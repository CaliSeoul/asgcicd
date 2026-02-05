# 🚀 ASG 연동 Nginx CI/CD 파이프라인 프로젝트

이 프로젝트는 GitHub Actions, S3, ECR, SSM을 사용하여 EC2 인스턴스에 Nginx를 배포하는 "완전체" CI/CD 파이프라인을 구축하기 위한 초기 설정입니다.

---

## 📂 프로젝트 구조

```
asgcicd/
├── .github/
│   └── workflows/
│       └── deploy.yml      # CI/CD 파이프라인의 모든 자동화 로직이 담긴 파일
├── html/
│   └── index.html        # S3에 업로드될 웹사이트의 메인 페이지
├── .gitignore              # Git이 추적하지 않을 파일 및 폴더 목록
├── default.conf            # S3에 업로드될 Nginx의 커스텀 설정 파일
├── Dockerfile              # Nginx 이미지를 만들기 위한 설계도
└── README.md               # 프로젝트 설명서 (바로 이 파일)
```

### 각 파일의 역할 (초심자 가이드)

*   **`deploy.yml`**: 이 프로젝트의 **자동화 총 감독**입니다. GitHub에 코드를 푸시하면, 이 파일에 적힌 순서대로 모든 작업(S3 업로드, Docker 이미지 빌드, EC2 배포)이 자동으로 실행됩니다.
*   **`html/index.html`**: 사용자가 실제로 보게 될 **웹페이지의 내용물**입니다. 이 파일은 Docker 이미지에 포함되지 않고 S3에 올라갑니다.
*   **`default.conf`**: Nginx 웹 서버의 **설정 파일**입니다. `index.html`을 어떻게 보여줄지 등을 결정합니다. 이 파일도 S3에 올라갑니다.
*   **`Dockerfile`**: **가벼운 Nginx 이미지를 만드는 설계도**입니다. 특이한 점은, 이 `Dockerfile`은 아무 파일도 복사하지 않습니다. 이미지를 최대한 가볍고 범용적으로 유지하기 위함입니다.
*   **`README.md`**: 프로젝트에 대한 설명을 담는 파일입니다.

---

## 🌊 CI/CD 파이프라인 흐름

이 프로젝트의 자동화 파이프라인은 다음과 같은 흐름으로 동작합니다.

1.  **코드 푸시 (GitHub)**: 사용자가 코드를 수정하고 `git push`를 합니다.

2.  **S3에 파일 업로드 (GitHub Actions)**:
    *   `deploy.yml`이 실행되어, `default.conf` 파일과 `html` 폴더의 내용물을 AWS S3 버킷으로 업로드합니다.
    *   **핵심:** 이렇게 하면 웹페이지 내용이나 Nginx 설정을 바꾸고 싶을 때, Docker 이미지를 매번 새로 빌드할 필요 없이 S3의 파일만 교체하면 됩니다.

3.  **Docker 이미지 빌드 & 푸시 (GitHub Actions)**:
    *   `Dockerfile`을 기반으로 **아무 내용도 포함되지 않은 순수한 Nginx 이미지**를 빌드합니다.
    *   빌드된 이미지에 고유한 태그(`github.sha`)와 `latest` 태그를 붙여 AWS ECR(Docker 이미지 저장소)에 푸시합니다.

4.  **EC2에 배포 (GitHub Actions & SSM)**:
    *   AWS SSM을 통해 EC2 인스턴스에 원격으로 접속하여 다음 명령들을 실행합니다.
    *   **파일 다운로드**: S3에 올려뒀던 `default.conf`와 `html` 폴더를 EC2 내부의 `/home/ubuntu/app/` 경로로 다운로드합니다.
    *   **Docker 이미지 가져오기**: ECR에서 방금 푸시한 최신 Docker 이미지를 가져옵니다 (`docker pull`).
    *   **컨테이너 실행**: `docker run` 명령어로 Nginx 컨테이너를 실행합니다.
        *   **가장 중요한 부분:** `-v` (볼륨 마운트) 옵션을 사용하여 **EC2에 다운로드한 파일들을 컨테이너 내부의 올바른 경로에 연결**합니다.
            *   EC2의 `/home/ubuntu/app/default.conf` → 컨테이너의 `/etc/nginx/conf.d/default.conf`
            *   EC2의 `/home/ubuntu/app/html` → 컨테이너의 `/usr/share/nginx/html`
        *   결과적으로, 순수한 Nginx 이미지가 EC2에 다운로드된 최신 설정과 HTML 파일을 사용하여 웹 서비스를 제공하게 됩니다.

### 🤔 "오토스케일링까지 곁들인..." 이란?

이 구조는 오토스케일링(Auto Scaling) 환경에 매우 적합합니다.

*   새로운 EC2 인스턴스가 오토스케일링 그룹에 의해 자동으로 생성될 때, **시작 스크립트(User Data)**를 통해 위 `deploy.yml`의 6단계(SSM)에서 실행된 것과 동일한 로직(S3에서 파일 다운로드, ECR에서 이미지 pull, 볼륨 마운트하여 컨테이너 실행)을 수행하도록 설정할 수 있습니다.
*   이렇게 하면 모든 새 인스턴스가 항상 최신 버전의 설정과 웹 콘텐츠를 가지고 동일한 상태로 실행될 수 있습니다.
*   `deploy.yml`의 `instance-ids`에 특정 인스턴스 대신, 오토스케일링 그룹의 모든 인스턴스를 타겟팅하도록 수정하면 여러 인스턴스에 동시 배포도 가능합니다.

---

## ✅ 다음 단계

1.  이 파일들을 GitHub 리포지토리(`https://github.com/CaliSeoul/asgcicd`)에 푸시합니다.
2.  GitHub 리포지토리의 `Settings > Secrets and variables > Actions`에 `deploy.yml`에서 사용하는 모든 Secret(`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `S3_BUCKET_NAME`, `ECR_REPOSITORY`, `EC2_INSTANCE_ID`)을 등록합니다.
3.  모든 설정이 완료되면, GitHub Actions가 자동으로 실행되어 배포가 진행됩니다.