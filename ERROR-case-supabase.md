# ERROR case: Supabase project inactive

작성일: 2026-05-10

이 문서는 대시보드에서 X 연동 정보가 입력되어 있었던 것 같은데도
`연결됨`으로 보이지 않았던 이유를 아주 쉽게 설명하기 위해 남긴 기록이다.

민감한 키, 토큰, 실제 비밀번호 값은 이 문서에 적지 않는다.

## 한 줄 요약

X 연동 정보가 없어졌다기보다, 그 정보를 보관하던 Supabase 프로젝트가
`INACTIVE` 상태라서 대시보드가 정보를 읽어오지 못한 상황이었다.

## 아주 쉽게 비유하면

이 앱은 혼자 모든 정보를 들고 있는 앱이 아니다.

앱은 이렇게 움직인다.

1. 대시보드 앱이 열린다.
2. 앱이 Supabase에게 묻는다.
   "X 연동 정보 저장해둔 거 있어?"
3. Supabase가 `sns_credentials` 테이블에서 `twitter` 정보를 찾아준다.
4. 앱은 그 안에 값이 있으면 화면에 `연결됨`이라고 보여준다.

여기서 Supabase는 온라인 창고 같은 역할을 한다.

그런데 이번에는 온라인 창고의 불이 꺼져 있었다.
즉, Supabase 프로젝트가 `INACTIVE` 상태였다.

그래서 앱 입장에서는 이런 상황이 된 것이다.

```text
앱: X 키 있어?
Supabase: ...
앱: 답이 안 오네. 그러면 일단 빈 값으로 보여줘야겠다.
화면: 연결됨 표시 안 함
```

중요한 점은, 화면에 `연결됨`이 안 떴다고 해서 반드시 X 키를 다시 입력하지
않았다는 뜻은 아니라는 점이다. Supabase에 연결하지 못하면 앱은 저장된 값을
읽을 수 없다.

## 이번에 확인된 사실

이번 상황에서 확인된 핵심은 다음과 같다.

- `.env`에는 실제 Supabase 연결 정보처럼 보이는 값이 들어 있었다.
- 앱은 데모 모드가 아니었다.
- 앱은 X 키를 `.env`에서 직접 읽지 않는다.
- X 키는 Supabase DB의 `sns_credentials` 테이블에 저장되는 구조다.
- Supabase 관리 API에서 `tearess's Project` 상태가 `INACTIVE`로 확인되었다.
- 프로젝트를 다시 활성화/restore한 뒤에는 연결이 다시 되는 흐름으로 보인다.

## X 연동 정보는 어디에 저장되나?

이 프로젝트에서 X 연동 정보는 `.env` 파일에 저장되는 것이 아니다.

화면에서 입력한 X 값들은 Supabase의 아래 테이블에 저장된다.

```text
table: sns_credentials
platform: twitter
credentials: X 관련 키들이 들어 있는 JSON
```

대시보드는 시작할 때 이 테이블을 읽는다.

```text
Supabase -> sns_credentials -> platform = twitter
```

그리고 읽어온 값 중 하나라도 있으면 `연결됨`이라고 표시한다.

## 왜 갑자기 안 보였나?

Supabase 프로젝트가 `INACTIVE` 상태가 되면, 앱이 DB에 물어볼 수 없다.

앱은 인터넷 너머의 Supabase DB에 가서 데이터를 읽어와야 하는데,
프로젝트가 비활성 상태면 DB가 자고 있는 것처럼 동작한다.

그래서 앱은 다음 데이터를 가져오지 못한다.

- X 연동 정보
- OpenAI 같은 서비스 연동 정보
- 저장된 콘텐츠
- 회원 정보
- 설정값

이번에는 특히 X 연동 화면에서 `twitter` credentials를 읽지 못해서
`연결됨` 표시가 나오지 않은 것이다.

## Supabase 프로젝트가 INACTIVE가 되는 경우

확인된 사실은 `INACTIVE` 상태였다는 점이다.

그 상태가 된 정확한 계기는 Supabase Dashboard의 프로젝트 히스토리나
이메일 알림을 봐야 더 정확히 알 수 있다. 다만 Supabase에는 Free 프로젝트를
pause/restore하는 기능이 있고, pause된 Free 프로젝트는 일정 기간 안에
Dashboard에서 복구할 수 있다.

공식 문서 참고:

- https://supabase.com/docs/guides/platform/upgrading#pause-and-restore
- https://supabase.com/docs/guides/troubleshooting/restore-project-after-90-days-pause

## 다시 활성화하는 방법

1. Supabase Dashboard에 들어간다.

```text
https://supabase.com/dashboard
```

2. `tearess's Project`를 찾는다.

3. 프로젝트 카드나 Project Overview에서 `Restore project` 또는 비슷한 복구 버튼을 누른다.

4. 복구가 끝날 때까지 기다린다.

5. 로컬 대시보드를 새로고침한다.

```text
http://127.0.0.1:5174/
```

6. `연동 관리 -> SNS 연동 -> X (Twitter)`로 가서 `연결됨` 표시를 확인한다.

## 다음에 같은 일이 생기면 확인할 순서

### 1. 앱이 Supabase에 연결되어 있는지 확인

`.env`에 아래 값이 있어야 한다.

```env
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
```

실제 값은 문서나 채팅에 붙여넣지 않는다.

### 2. Supabase 프로젝트 상태 확인

Supabase Dashboard에서 프로젝트가 Active인지 확인한다.

프로젝트가 `Inactive`, `Paused`, `Restoring` 상태면 앱이 DB를 제대로 읽지 못할 수 있다.

### 3. 테이블이 있는지 확인

Supabase Dashboard의 Table Editor에서 아래 테이블을 확인한다.

```text
sns_credentials
```

### 4. X 행이 있는지 확인

`sns_credentials` 테이블에 아래 행이 있어야 한다.

```text
platform = twitter
```

이 행의 `credentials` 안에 X 키들이 저장된다.

### 5. X 발행에 필요한 값 확인

X에 실제로 글을 올리려면 최소한 아래 4개가 필요하다.

```text
consumerKey
consumerKeySecret
accessToken
accessTokenSecret
```

화면에 Bearer Token, Client ID, Client Secret도 있지만,
현재 `post-x` Edge Function은 OAuth 1.0a 방식으로 위 4개 값을 사용한다.

## 헷갈리기 쉬운 점

### `.env`에 있는 Supabase 키와 X 키는 다르다

`.env`의 Supabase 키는 앱이 Supabase 창고에 들어가기 위한 출입증이다.

X 키는 X에 글을 올리기 위한 출입증이다.

둘은 서로 다르다.

```text
Supabase 키: 앱이 DB에 접속하기 위한 키
X 키: X API에 글을 올리기 위한 키
```

### 화면의 `연결됨`은 진짜 API 테스트가 아니다

현재 대시보드의 `연결됨` 표시는 "값이 저장되어 있나?"에 가깝다.

즉, `연결됨`은 이런 뜻이다.

```text
DB에서 twitter credentials를 읽었고, 그 안에 빈 값이 아닌 값이 있다.
```

하지만 이것만으로 X 발행이 반드시 성공한다는 뜻은 아니다.

X 발행 성공까지 확인하려면 실제 게시를 시도하거나, `post-x` Edge Function 호출 결과를 봐야 한다.

## 앞으로 기억할 문장

대시보드가 `연결됨`을 보여주려면, 두 가지가 모두 필요하다.

```text
1. Supabase 프로젝트가 깨어 있어야 한다.
2. sns_credentials 테이블에 twitter 키가 저장되어 있어야 한다.
```

이번 문제는 1번, 즉 Supabase 프로젝트가 `INACTIVE`였던 것이 핵심 원인이었다.
