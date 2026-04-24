# Quick Start

SNS 대시보드를 가장 빨리 사용하는 방법만 정리한 문서입니다.

## 1. 실행하기

터미널에서 프로젝트 폴더로 이동한 뒤 실행합니다.

```bash
npm run dev -- --host 127.0.0.1 --port 5174
```

브라우저에서 엽니다.

```text
http://127.0.0.1:5174/
```

현재 설정은 로그인 없이 바로 들어가는 모드입니다.

```env
VITE_DISABLE_AUTH=true
```

## 2. 글 만들기

1. 왼쪽 메뉴에서 `콘텐츠 관리` 클릭
2. `새 콘텐츠` 클릭
3. 제목 입력
4. 마스터 글 입력
5. 올릴 플랫폼 선택
6. 플랫폼별 글 작성
7. 저장

## 3. X에 바로 게시하기

먼저 X 키를 저장해야 합니다.

1. `연동 관리` 클릭
2. `SNS 연동` 클릭
3. `X (Twitter)` 항목에 아래 값 입력
   - Consumer Key
   - Consumer Key Secret
   - Access Token
   - Access Token Secret
4. 저장

게시할 때는:

1. `콘텐츠 관리`에서 글 열기
2. X(Twitter) 글 내용 확인
3. `즉시 발행` 클릭
4. 성공하면 X 게시 URL 확인

## 4. AI 초안 만들기

OpenAI API 키가 필요합니다.

1. `연동 관리` 클릭
2. `서비스 연동` 클릭
3. `OpenAI`에 API 키 저장
4. 콘텐츠 편집 화면에서 마스터 글 입력
5. 프롬프트 선택 또는 입력
6. 초안 생성 실행
7. 결과를 확인하고 수정

## 5. 자주 보는 문제

### 화면이 하얗게 나올 때

개발 서버를 다시 켭니다.

```bash
npm run dev -- --host 127.0.0.1 --port 5174
```

그리고 브라우저를 새로고침합니다.

### 로그인 화면이 나올 때

`.env`에 아래 값이 있는지 확인합니다.

```env
VITE_DISABLE_AUTH=true
```

값을 바꿨다면 개발 서버를 다시 시작합니다.

### X 게시가 안 될 때

대부분 X 키가 저장되지 않은 경우입니다.

`연동 관리 -> SNS 연동 -> X (Twitter)`에서 4개 키가 모두 저장되어 있는지 확인합니다.

만약 `schema cache` 또는 `public.sns_credentials` 오류가 나오면 Supabase 테이블이 아직 만들어지지 않은 것입니다. Supabase Dashboard의 `SQL Editor`에서 `supabase/setup.sql` 내용을 실행한 뒤 다시 저장합니다.

## 6. 지금 상태

- 로컬 접속 주소: `http://127.0.0.1:5174/`
- 로그인: 꺼짐
- Supabase 연결: 사용 중
- X 게시 함수: 배포됨
- X 게시 전 필요한 것: X API 키 저장
