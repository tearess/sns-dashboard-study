# 개발 일지

작성일: 2026-04-25  
프로젝트: SNS 대시보드 스터디

## 1. 프로젝트 개요

이 프로젝트는 Facebook, X(Twitter), Instagram, Threads, YouTube 콘텐츠를 한 곳에서 관리하고 발행하기 위한 SNS 운영 대시보드이다. 프론트엔드는 React + Vite로 구성되어 있고, 데이터 저장과 인증, Edge Function 실행은 Supabase를 사용한다.

초기 README 기준으로 이 앱은 다음 기능을 목표로 한다.

- 콘텐츠 목록, 작성, 편집, 캘린더 관리
- SNS별 초안 작성 및 저장
- OpenAI API를 통한 초안 자동 생성
- X(Twitter) 즉시 발행
- SNS/API 키 연동 관리
- 회원 가입, 승인, 권한 관리

현재 개발 방향은 "혼자 사용하는 내부 도구"에 맞춰 인증 진입 장벽을 낮추고, 실제 Supabase와 X 발행 함수가 붙을 수 있는 상태로 정리하는 것이다.

## 2. 기술 스택과 구조

주요 파일은 다음과 같다.

- `dashboard.jsx`: 메인 대시보드 UI와 대부분의 상태/업무 로직
- `main.jsx`: React 앱 진입점
- `supabase.js`: Supabase 클라이언트 및 데모 모드 클라이언트
- `supabase/functions/post-x/index.ts`: X(Twitter) 게시용 Supabase Edge Function
- `.env.example`: 환경변수 템플릿
- `README.md`: 설치, Supabase 테이블 생성, 실행 안내 문서

프론트엔드 빌드는 Vite가 담당한다. 로컬 개발 서버는 기본 포트 `5173`을 쓰지만, 작업 당시 다른 Vite 서버가 이미 `5173`을 사용 중이라 이 프로젝트는 `5174`로 실행했다.

```bash
npm run dev -- --host 127.0.0.1 --port 5174
```

## 3. 개발 방식

이번 작업은 다음 순서로 진행했다.

1. README를 먼저 읽고 의도된 사용 흐름을 파악했다.
2. 실제 파일 구조와 README 설명이 맞는지 확인했다.
3. 로컬 실행에 필요한 최소 환경을 구성했다.
4. 브라우저 흰 화면 문제를 먼저 해결했다.
5. Supabase/X 발행 경로를 실제로 호출해보며 원격 상태를 확인했다.
6. 인증/회원 승인 흐름이 혼자 쓰는 도구에 과한지 판단하고, 로그인 비활성화 모드를 추가했다.
7. 매 변경 후 `vite build`와 브라우저 렌더 확인으로 검증했다.

개발 원칙은 다음과 같았다.

- 비밀키나 토큰은 코드와 문서에 남기지 않는다.
- 실제 운영 경로와 데모 경로를 분리하되, 데모 모드에서도 앱이 깨지지 않게 한다.
- Supabase 연결 여부와 관계없이 UI를 확인할 수 있어야 한다.
- 원격 인프라 변경은 명시적으로 승인받고 진행한다.
- 혼자 쓰는 도구라면 사용성을 우선하되, 나중에 인증을 다시 켤 수 있도록 환경변수로 제어한다.

## 4. 초기 실행 환경 구성

README에 따라 `.env.example`을 복사해 `.env`를 만들었다. 처음에는 Supabase 값이 placeholder였기 때문에 앱은 데모 모드로 실행되었다.

의존성 설치는 `npm install`로 진행했다. 이 과정에서 `package-lock.json`이 새로 생성되었다. 기존 저장소에는 `bun.lock`도 있었지만, README는 `npm install`을 기준으로 안내하고 있어서 npm 흐름을 따랐다.

초기 실행 중 기본 포트 `5173`이 이미 사용 중이라 `5174`로 개발 서버를 띄웠다.

```bash
npm run dev -- --host 127.0.0.1 --port 5174
```

## 5. 흰 화면 문제 진단과 수정

처음 브라우저에서 앱을 열었을 때 흰 화면이 나왔다. 원인은 React 렌더링 중 런타임 에러가 발생했기 때문이다.

핵심 원인은 `supabase.js`의 데모 모드 더미 클라이언트가 실제 앱에서 호출하는 Supabase API 형태를 충분히 흉내 내지 못한 점이었다.

앱은 시작 시 다음과 같은 호출을 한다.

- `supabase.auth.getSession()`
- `supabase.from("settings").select("value").eq("key", "...").single()`
- `supabase.from("members").select("*").order(...)`
- `supabase.functions.invoke("post-x", ...)`

하지만 기존 더미 클라이언트에는 `auth`가 없었고, `.select().eq().single()` 같은 체인 호출도 완전히 지원하지 않았다. 그래서 데모 모드에서도 React가 초기 렌더 도중 깨졌다.

수정 내용:

- `supabase.js`에 `createDemoQuery()`를 추가했다.
- 데모 모드에서도 `select`, `order`, `eq`, `single`, `then` 체인이 동작하도록 했다.
- `auth.getSession`, `auth.signInWithPassword`, `auth.signUp`, `auth.signOut` 더미 메서드를 추가했다.
- 쓰기 동작은 실제 저장하지 않고 "데모 모드: Supabase 미연결" 메시지를 반환하도록 했다.

또 다른 잠재 원인도 함께 막았다. 브라우저 `localStorage`에 깨진 JSON이 저장되어 있으면 앱 초기 상태 생성 중 `JSON.parse`가 실패할 수 있었다. 이를 막기 위해 `dashboard.jsx`에 `readStoredJson()` 헬퍼를 추가했다.

이후 `vite build`가 성공했고, Chrome headless로 실제 DOM이 대시보드까지 렌더링되는 것을 확인했다.

## 6. Supabase 실제 연결 전환

이후 `.env`에 실제 Supabase URL과 anon key가 들어왔다. 이 값들은 문서에 기록하지 않는다.

실제 연결 후 X 게시를 시도하기 위해 Supabase Edge Function 경로를 호출했다.

처음에는 다음 응답이 나왔다.

```json
{
  "code": "NOT_FOUND",
  "message": "Requested function was not found"
}
```

이는 원격 Supabase 프로젝트에 `post-x` Edge Function이 아직 배포되지 않았다는 뜻이었다.

사용자 승인 후 다음 명령으로 로컬 함수 코드를 원격 Supabase 프로젝트에 배포했다.

```bash
npx supabase functions deploy post-x --project-ref <project-ref>
```

배포 결과:

- `post-x` 함수 업로드 성공
- Supabase Dashboard의 Functions 메뉴에서 확인 가능한 상태가 됨

그 뒤 다시 게시 함수를 호출했지만 다음 응답을 받았다.

```json
{
  "error": "X 인증키를 찾을 수 없습니다. 연동 관리에서 저장해주세요."
}
```

즉 함수 배포는 성공했지만, 원격 Supabase의 `sns_credentials` 테이블에 `platform = 'twitter'` 인증 정보가 아직 없었다.

## 7. X(Twitter) 게시 흐름

X 게시의 의도된 흐름은 다음과 같다.

1. 사용자가 대시보드의 `연동 관리 -> SNS 연동 -> X (Twitter)`에서 키를 저장한다.
2. 키는 Supabase `sns_credentials` 테이블에 저장된다.
3. 프론트엔드에서 게시 요청을 보낸다.
4. Supabase Edge Function `post-x`가 서버 쪽에서 `sns_credentials`를 조회한다.
5. Edge Function이 OAuth 1.0a 서명을 만들어 X API v2 `/2/tweets`에 게시한다.

필요한 X 키:

- Consumer Key
- Consumer Key Secret
- Access Token
- Access Token Secret

중요한 점:

- X 키를 로컬로 직접 꺼내서 우회 게시하지 않았다.
- 서버 함수가 Supabase Service Role Key로 안전하게 조회하고 게시하는 정상 경로를 유지했다.
- 현재 남은 작업은 대시보드에서 X 키를 저장한 뒤 게시를 재시도하는 것이다.

## 8. 회원가입/로그인 흐름과 문제

처음 앱은 Supabase Auth + `members` 테이블 승인 흐름을 갖고 있었다.

원래 흐름:

1. 이메일/비밀번호로 회원가입
2. Supabase Auth에 사용자 생성
3. `members` 테이블에 `approval_status = 'pending'`으로 행 생성
4. 관리자가 승인
5. `approval_status = 'approved'`인 사용자만 대시보드 접근

하지만 실제 원격 Supabase의 `members` 테이블 구조가 README 및 앱 코드와 맞지 않았다.

확인된 상태:

- `members.id` 존재
- `members.created_at` 존재
- `members.name` 없음
- `members.email` 없음
- `members.joined_at` 없음
- `members.approval_status` 없음
- `members.role` 없음

이 때문에 `tearess7@gmail.com`으로 가입 신청을 해도 앱이 기대하는 승인용 행을 정상적으로 만들거나 조회할 수 없었다. Supabase Dashboard 메뉴에서 수동 승인하는 방법을 안내했지만, 실제 테이블 스키마 자체가 달라서 근본 해결이 필요했다.

## 9. 초기 관리자 우회 처리

처음에는 `VITE_BOOTSTRAP_ADMIN_EMAIL` 환경변수를 도입해 특정 이메일을 초기 관리자처럼 통과시키는 방식을 추가했다.

추가한 개념:

- `VITE_BOOTSTRAP_ADMIN_EMAIL=tearess7@gmail.com`
- 해당 이메일로 Supabase Auth 로그인에 성공하면 `members` 승인 여부와 관계없이 `admin` 역할로 통과

이 방식은 정식 회원 승인 테이블이 준비되기 전 임시 관리자 진입용으로 쓸 수 있다.

하지만 사용자가 "나만 사용하는 도구"라고 판단했기 때문에 이후 더 단순한 방향으로 바꾸었다.

## 10. 로그인 비활성화 모드 추가

혼자 사용하는 내부 도구라면 로그인 화면은 불필요한 마찰이 된다. 그래서 인증을 완전히 끌 수 있는 환경변수를 추가했다.

추가한 환경변수:

```env
VITE_DISABLE_AUTH=true
```

동작:

- `VITE_DISABLE_AUTH=true`이면 Supabase Auth 세션 확인을 하지 않는다.
- 앱은 즉시 `approved` 상태로 진입한다.
- `currentUser`는 로컬 관리자 객체로 설정된다.
- 사이드바의 로그아웃 버튼은 숨긴다.

나중에 다시 로그인 기능을 켜고 싶으면 다음처럼 바꾸면 된다.

```env
VITE_DISABLE_AUTH=false
```

이 방식은 개인 로컬 도구나 내부망 도구에는 편하지만, 공개 배포에는 적합하지 않다. Vercel 등 공개 URL로 배포할 경우에는 반드시 인증을 다시 켜야 한다.

## 11. 현재 주요 변경 파일

### `supabase.js`

변경 목적:

- 데모 모드에서도 앱이 흰 화면으로 깨지지 않게 함
- 실제 Supabase API 호출 형태를 더 충실히 흉내 냄

주요 변경:

- `createDemoQuery()` 추가
- `auth` 더미 메서드 추가
- `functions.invoke()` 더미 응답 유지
- select/order/eq/single/then 체인 지원

### `dashboard.jsx`

변경 목적:

- localStorage 파싱 오류 방어
- 초기 관리자 우회
- 로그인 비활성화 모드 지원
- 로그인 비활성화 시 로그아웃 버튼 숨김

주요 변경:

- `readStoredJson()` 추가
- `BOOTSTRAP_ADMIN_EMAIL` 추가
- `DISABLE_AUTH` 추가
- `localAdmin` 객체 추가
- 앱 시작 시 `DEMO_MODE || DISABLE_AUTH`이면 바로 승인 상태로 진입
- 로그인 성공 후 bootstrap admin이면 승인 테이블 확인 없이 진입

### `.env.example`

변경 목적:

- 새 인증 관련 환경변수의 사용법을 템플릿에 남김

추가 항목:

```env
VITE_BOOTSTRAP_ADMIN_EMAIL=admin@example.com
VITE_DISABLE_AUTH=false
```

### `supabase/functions/post-x/index.ts`

변경하지는 않았지만, 원격 Supabase 프로젝트에 배포했다.

역할:

- 요청 본문에서 `text`를 받음
- Supabase `sns_credentials` 테이블에서 `platform = 'twitter'` 행을 조회
- X API v2에 OAuth 1.0a 방식으로 게시
- 성공 시 게시 URL을 반환

## 12. 검증 기록

진행 중 다음 검증을 반복했다.

- `npm install` 성공
- `npm run dev -- --host 127.0.0.1 --port 5174` 실행
- `vite build` 성공
- Chrome headless로 대시보드 렌더 확인
- 로그인 비활성화 후 로그인 화면 없이 `SNS 대시보드 / 콘텐츠 관리`가 바로 뜨는 것 확인
- Supabase Edge Function `post-x` 배포 성공
- 배포된 함수 호출 성공
- X 인증키 미저장 상태에서는 함수가 안전하게 에러 반환하는 것 확인

## 13. 현재 실행 방법

현재 개발 서버 실행:

```bash
npm run dev -- --host 127.0.0.1 --port 5174
```

접속:

```text
http://127.0.0.1:5174/
```

현재 `.env`에서 인증 비활성화 모드가 켜져 있으므로 로그인 화면 없이 바로 대시보드가 열린다.

## 14. 다음 작업 후보

### 1. X 키 저장 후 게시 재시도

대시보드에서 다음 메뉴로 이동한다.

```text
연동 관리 -> SNS 연동 -> X (Twitter)
```

다음 값을 저장한다.

- Consumer Key
- Consumer Key Secret
- Access Token
- Access Token Secret

저장 후 `post-x` 함수를 다시 호출하면 실제 X 게시가 가능해야 한다.

### 2. Supabase 테이블 스키마 정리

현재 `members` 테이블은 앱이 기대하는 구조와 다르다. 로그인 기능을 다시 살리려면 README의 스키마와 실제 Supabase 테이블을 맞춰야 한다.

필요한 컬럼:

- `name text`
- `email text unique`
- `joined_at text`
- `approval_status text default 'pending'`
- `role text default 'operator'`

### 3. 인증 모드 정책 정리

개인 로컬 사용:

```env
VITE_DISABLE_AUTH=true
```

공개 배포 또는 팀 사용:

```env
VITE_DISABLE_AUTH=false
```

팀 사용으로 전환할 경우 `members` 테이블과 Supabase Auth 이메일 인증 정책을 함께 정리해야 한다.

### 4. 민감정보 저장 정책 개선

현재 SNS 키는 Supabase DB의 `sns_credentials` 테이블에 저장하는 구조다. 장기적으로는 다음 개선을 검토할 수 있다.

- RLS 정책 정리
- 서버 전용 API를 통한 저장
- 키 암호화 또는 Secret Manager 사용
- 운영/개발 Supabase 프로젝트 분리

## 15. 개발상의 교훈

이번 작업에서 가장 중요한 포인트는 "문서상 가능한 흐름"과 "실제 연결된 원격 환경"이 다를 수 있다는 점이었다.

README는 Supabase 테이블 구조와 실행 방식을 안내하지만, 실제 원격 Supabase에는 일부 테이블 컬럼이 맞지 않았다. 그래서 UI만 보고 해결하기보다 API 응답과 빌드 결과, 브라우저 렌더링 결과를 함께 확인해야 했다.

또한 개인용 도구에서는 완성도 높은 인증 흐름보다 "바로 들어가서 작업할 수 있는 흐름"이 더 중요할 수 있다. 그래서 로그인 기능을 삭제하지 않고, 환경변수로 끌 수 있게 만든 것이 현재 코드베이스에 가장 맞는 타협점이다.

현재 상태는 다음과 같이 요약할 수 있다.

- 앱은 로컬에서 로그인 없이 바로 열린다.
- Supabase 연결은 실제 값으로 구성되어 있다.
- X 게시용 Edge Function은 원격에 배포되어 있다.
- 아직 X 인증키가 DB에 저장되지 않아 실제 게시는 대기 상태다.
- 회원 승인 기능은 나중에 팀 사용으로 확장할 때 테이블 스키마 정리가 필요하다.
