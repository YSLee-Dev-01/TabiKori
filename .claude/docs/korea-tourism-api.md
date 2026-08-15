# 한국관광공사 다국어 관광정보 서비스 (EngService2) API

## 서비스 개요

| 항목 | 내용 |
|------|------|
| Base URL | `https://apis.data.go.kr/B551011/EngService2` |
| 인증 방식 | Service Key (URL-Encode) |
| 응답 형식 | XML (기본), JSON (`_type=json` 추가 시) |
| 데이터 갱신 | 일 1회 |
| 지원 언어 | 영(Eng), 일(Jpn), 중간(Chs), 중번(Cht), 독(Ger), 불(Fre), 스페인(Spn), 러(Rus) |

> 언어 변경 시 URL의 `EngService2` 부분을 `JpnService2` 등으로 교체
> 예) `https://apis.data.go.kr/B551011/JpnService2/~~`

---

## 공통 Request Parameter

모든 API에 공통으로 적용:

| 파라미터 | 필수 | 설명 |
|---------|------|------|
| `ServiceKey` | ✅ | 공공데이터포털 인증키 (URL-Encode) |
| `MobileOS` | ✅ | `IOS` / `AND` / `WIN` / `ETC` |
| `MobileApp` | ✅ | 앱/서비스명 |
| `numOfRows` | - | 페이지당 결과수 (기본 10) |
| `pageNo` | - | 페이지 번호 (기본 1) |
| `_type` | - | `json` 지정 시 JSON 응답 (미지정 시 XML) |

---

## ContentTypeId 코드표

| 타입 | ContentTypeId |
|------|--------------|
| 관광지 | `76` |
| 교통 | `77` |
| 문화시설 | `78` |
| 쇼핑 | `79` |
| 숙박 | `80` |
| 음식점 | `82` |
| 행사/공연/축제 | `85` |
| 레포츠 | `75` |

---

## 에러 코드

### 공공데이터포털 에러 (XML only)

```xml
<OpenAPI_ServiceResponse>
  <cmmMsgHeader>
    <errMsg>SERVICE ERROR</errMsg>
    <returnAuthMsg>SERVICE_KEY_IS_NOT_REGISTERED_ERROR</returnAuthMsg>
    <returnReasonCode>30</returnReasonCode>
  </cmmMsgHeader>
</OpenAPI_ServiceResponse>
```

| 코드 | 메시지 | 설명 |
|------|--------|------|
| `01` | APPLICATION_ERROR | 어플리케이션 에러 |
| `12` | NO_OPENAPI_SERVICE_ERROR | 해당 OpenAPI 서비스 없음/폐기 |
| `20` | SERVICE_ACCESS_DENIED_ERROR | 서비스 접근 거부 |
| `22` | LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR | 요청 제한 횟수 초과 |
| `30` | SERVICE_KEY_IS_NOT_REGISTERED_ERROR | 등록되지 않은 서비스키 |
| `31` | DEADLINE_HAS_EXPIRED_ERROR | 활용기간 만료 |
| `32` | UNREGISTERED_IP_ERROR | 등록되지 않은 IP |
| `99` | UNKNOWN_ERROR | 기타 에러 |

### 제공기관 에러

| 코드 | 메시지 | 설명 |
|------|--------|------|
| `00` | NORMAL_CODE | 정상 |
| `01` | APPLICATION_ERROR | 어플리케이션 에러 |
| `02` | DB_ERROR | 데이터베이스 에러 |
| `03` | NODATA_ERROR | 데이터 없음 |
| `04` | HTTP_ERROR | HTTP 에러 |
| `05` | SERVICETIMEOUT_ERROR | 서비스 연결 실패 |
| `10` | INVALID_REQUEST_PARAMETER_ERROR | 잘못된 요청 파라미터 |
| `11` | NO_MANDATORY_REQUEST_PARAMETERS_ERROR | 필수 파라미터 누락 |
| `20` | SERVICE_ACCESS_DENIED_ERROR | 서비스 접근 거부 |
| `21` | TEMPORARILY_DISABLE_THE_SERVICEKEY_ERROR | 일시적으로 사용 불가 서비스키 |
| `22` | LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR | 요청 제한 횟수 초과 |
| `30` | SERVICE_KEY_IS_NOT_REGISTERED_ERROR | 등록되지 않은 서비스키 |
| `31` | DEADLINE_HAS_EXPIRED_ERROR | 활용기간 만료 |
| `32` | UNREGISTERED_IP_ERROR | 등록되지 않은 IP |
| `33` | UNSIGNED_CALL_ERROR | 서명되지 않은 호출 |
| `99` | UNKNOWN_ERROR | 기타 에러 |

---

## 공통 Response 구조

```json
{
  "response": {
    "header": {
      "resultCode": "0000",
      "resultMsg": "OK"
    },
    "body": {
      "items": { "item": [...] },
      "numOfRows": 10,
      "pageNo": 1,
      "totalCount": 100
    }
  }
}
```

---

## API 목록

| # | 오퍼레이션명 | Endpoint |
|---|------------|---------|
| 1 | 법정동코드 조회 | `ldongCode2` |
| 2 | 분류체계코드 조회 | `lclsSystmCode2` |
| 3 | 지역기반 관광정보 조회 | `areaBasedList2` |
| 4 | 위치기반 관광정보 조회 | `locationBasedList2` |
| 5 | 키워드 검색 조회 | `searchKeyword2` |
| 6 | 행사정보 조회 | `searchFestival2` |
| 7 | 숙박정보 조회 | `searchStay2` |
| 8 | 공통정보 조회 (상세정보1) | `detailCommon2` |
| 9 | 소개정보 조회 (상세정보2) | `detailIntro2` |
| 10 | 반복정보 조회 (상세정보3) | `detailInfo2` |
| 11 | 이미지정보 조회 (상세정보4) | `detailImage2` |
| 12 | 다국어 관광정보 동기화 목록 조회 | `areaBasedSyncList2` |

---

## 1. 법정동코드 조회 `ldongCode2`

```
GET /ldongCode2
```

지역기반 관광정보 조회 시 사용할 시도/시군구 코드를 조회한다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `lDongRegnCd` | - | `11` | 시도 코드 (없으면 전체 시도 목록 반환) |
| `lDongListYn` | - | `N` | `N`: 코드 조회 / `Y`: 전체 목록 조회 |

### Response (lDongListYn=N)

| 필드 | 설명 |
|------|------|
| `code` | 시도 or 시군구 코드 |
| `name` | 지역명 |
| `rnum` | 일련번호 |

### Response (lDongListYn=Y)

| 필드 | 설명 |
|------|------|
| `lDongRegnCd` | 시도 코드 |
| `lDongRegnNm` | 시도명 |
| `lDongSignguCd` | 시군구 코드 |
| `lDongSignguNm` | 시군구명 |
| `rnum` | 일련번호 |

### 예시

```
# 서울(11) 시군구 코드 조회
GET /ldongCode2?serviceKey=인증키&numOfRows=10&pageNo=1&MobileOS=ETC&MobileApp=APP&_type=json&lDongRegnCd=11&lDongListYn=N
```

```json
{
  "response": {
    "header": { "resultCode": "0000", "resultMsg": "OK" },
    "body": {
      "items": {
        "item": [
          { "rnum": 1, "code": "110", "name": "Jongno-gu" },
          { "rnum": 2, "code": "140", "name": "Jung-gu" }
        ]
      },
      "numOfRows": 10, "pageNo": 1, "totalCount": 25
    }
  }
}
```

---

## 2. 분류체계코드 조회 `lclsSystmCode2`

```
GET /lclsSystmCode2
```

관광타입별 대/중/소 분류체계 코드를 조회한다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `lclsSystm1` | - | `A01` | 대분류 코드 |
| `lclsSystm2` | - | `A0101` | 중분류 코드 (lclsSystm1 필수) |
| `lclsSystm3` | - | `A01010100` | 소분류 코드 (lclsSystm1, lclsSystm2 필수) |
| `lclsSystmListYn` | - | `N` | `N`: 코드 조회 / `Y`: 전체 목록 조회 |

### Response (lclsSystmListYn=N)

| 필드 | 설명 |
|------|------|
| `code` | 분류체계 코드 |
| `name` | 분류체계 코드명 |
| `rnum` | 일련번호 |

### Response (lclsSystmListYn=Y)

| 필드 | 설명 |
|------|------|
| `lclsSystm1Cd` / `lclsSystm1Nm` | 대분류 코드 / 명 |
| `lclsSystm2Cd` / `lclsSystm2Nm` | 중분류 코드 / 명 |
| `lclsSystm3Cd` / `lclsSystm3Nm` | 소분류 코드 / 명 |
| `rnum` | 일련번호 |

---

## 3. 지역기반 관광정보 조회 `areaBasedList2`

```
GET /areaBasedList2
```

시도/시군구 기반으로 관광정보 목록을 조회한다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `arrange` | - | `C` | `A`=제목순, `C`=수정일순, `D`=생성일순 / `O`,`Q`,`R`=이미지 우선 정렬 |
| `contentTypeId` | - | `78` | ContentTypeId 코드 참고 |
| `lDongRegnCd` | - | `11` | 시도 코드 |
| `lDongSignguCd` | - | `110` | 시군구 코드 (lDongRegnCd 필수) |
| `lclsSystm1` | - | - | 대분류 |
| `lclsSystm2` | - | - | 중분류 (lclsSystm1 필수) |
| `lclsSystm3` | - | - | 소분류 (lclsSystm1, lclsSystm2 필수) |
| `modifiedtime` | - | `20200413` | 수정일 필터 (YYYYMMDD) |

### Response

| 필드 | 필수 | 설명 |
|------|------|------|
| `contentid` | ✅ | 콘텐츠 ID |
| `contenttypeid` | ✅ | 콘텐츠 타입 ID |
| `title` | ✅ | 제목 |
| `createdtime` | ✅ | 등록일 (yyyyMMddHHmmss) |
| `modifiedtime` | ✅ | 수정일 (yyyyMMddHHmmss) |
| `addr1` | - | 주소 |
| `addr2` | - | 상세 주소 |
| `zipcode` | - | 우편번호 |
| `tel` | - | 전화번호 |
| `firstimage` | - | 대표이미지 원본 URL (~500×333) |
| `firstimage2` | - | 대표이미지 썸네일 URL (~150×100) |
| `cpyrhtDivCd` | - | `Type1`: 출처표시 / `Type3`: 출처표시+변경금지 |
| `mapx` | - | 경도 (WGS84) |
| `mapy` | - | 위도 (WGS84) |
| `mlevel` | - | 지도 레벨 |
| `lDongRegnCd` | - | 시도 코드 |
| `lDongSignguCd` | - | 시군구 코드 |
| `lclsSystm1` / `lclsSystm2` / `lclsSystm3` | - | 분류체계 코드 |

### 예시

```
GET /areaBasedList2?serviceKey=인증키&numOfRows=10&pageNo=1&MobileOS=ETC&MobileApp=AppTest&_type=json&arrange=C&contentTypeId=85&lDongRegnCd=47&lDongSignguCd=130
```

---

## 4. 위치기반 관광정보 조회 `locationBasedList2`

```
GET /locationBasedList2
```

GPS 좌표 기반으로 반경 내 관광정보 목록을 조회한다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `mapX` | ✅ | `126.981611` | 경도 (WGS84) |
| `mapY` | ✅ | `37.568477` | 위도 (WGS84) |
| `radius` | ✅ | `1000` | 반경 (단위: m, 최대 20,000) |
| `arrange` | - | `E` | `A`=제목, `B`=조회수, `C`=수정일, `D`=생성일, `E`=거리순 / `O`,`Q`,`R`,`S`=이미지 우선 |
| `contentTypeId` | - | - | ContentTypeId 코드 참고 |
| `modifiedtime` | - | - | 수정일 필터 |

### Response

지역기반 관광정보 응답 필드와 동일 + 추가:

| 필드 | 설명 |
|------|------|
| `dist` | 중심 좌표로부터의 거리 (단위: m) |

### 예시

```
# 서울 한국관광공사 주변 10km 이내 문화시설 조회
GET /locationBasedList2?serviceKey=인증키&numOfRows=10&pageNo=1&MobileOS=ETC&MobileApp=AppTest&_type=json&arrange=E&mapX=126.981611&mapY=37.568477&radius=10000&contentTypeId=78
```

---

## 5. 키워드 검색 조회 `searchKeyword2`

```
GET /searchKeyword2
```

키워드로 관광정보를 검색한다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `keyword` | ✅ | `시장` | 검색 키워드 (영문 외 URL 인코딩 필요) |
| `arrange` | - | `C` | `A`=제목순, `C`=수정일순, `D`=생성일순 |
| `contentTypeId` | - | - | ContentTypeId 코드 참고 |
| `lDongRegnCd` | - | - | 시도 코드 |
| `lDongSignguCd` | - | - | 시군구 코드 (lDongRegnCd 필수) |
| `lclsSystm1` / `lclsSystm2` / `lclsSystm3` | - | - | 분류체계 코드 |

### Response

지역기반 관광정보 조회와 동일

---

## 6. 행사정보 조회 `searchFestival2`

```
GET /searchFestival2
```

행사/공연/축제 정보를 날짜 기반으로 조회한다. contentTypeId=85 전용.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `eventStartDate` | ✅ | `20260101` | 행사 시작일 (YYYYMMDD) |
| `eventEndDate` | - | `20261231` | 행사 종료일 (YYYYMMDD) |
| `arrange` | - | `A` | 정렬 구분 |
| `lDongRegnCd` | - | - | 시도 코드 |
| `lDongSignguCd` | - | - | 시군구 코드 |
| `modifiedtime` | - | - | 수정일 필터 |

### Response

지역기반 관광정보 응답 필드와 동일 + 추가:

| 필드 | 설명 |
|------|------|
| `eventstartdate` | 행사 시작일 (YYYYMMDD) |
| `eventenddate` | 행사 종료일 (YYYYMMDD) |

### 예시

```
# 2026년 행사 조회
GET /searchFestival2?serviceKey=인증키&numOfRows=10&pageNo=1&MobileOS=ETC&MobileApp=AppTest&_type=json&arrange=C&eventStartDate=20260101&eventEndDate=20261231
```

---

## 7. 숙박정보 조회 `searchStay2`

```
GET /searchStay2
```

베니키아·한옥·굿스테이 숙박 목록을 조회한다. contentTypeId=80 전용.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `arrange` | - | `A` | 정렬 구분 |
| `lDongRegnCd` | - | - | 시도 코드 |
| `lDongSignguCd` | - | - | 시군구 코드 (lDongRegnCd 필수) |
| `modifiedtime` | - | - | 수정일 필터 |

### Response

지역기반 관광정보 조회와 동일

---

## 8. 공통정보 조회 `detailCommon2` (상세정보1)

```
GET /detailCommon2
```

콘텐츠 ID로 공통 정보(제목, 주소, 개요 등)를 조회한다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `contentId` | ✅ | `2815432` | 콘텐츠 ID |

### Response

| 필드 | 필수 | 설명 |
|------|------|------|
| `contentid` | ✅ | 콘텐츠 ID |
| `contenttypeid` | ✅ | 콘텐츠 타입 ID |
| `title` | ✅ | 콘텐츠명 |
| `createdtime` | ✅ | 등록일 (yyyyMMddHHmmss) |
| `modifiedtime` | ✅ | 수정일 (yyyyMMddHHmmss) |
| `homepage` | - | 홈페이지 주소 |
| `tel` | - | 전화번호 |
| `telname` | - | 전화번호명 |
| `addr1` | - | 주소 |
| `addr2` | - | 상세주소 |
| `zipcode` | - | 우편번호 |
| `mapx` | - | 경도 (WGS84) |
| `mapy` | - | 위도 (WGS84) |
| `mlevel` | - | 지도 레벨 |
| `firstimage` | - | 원본 이미지 URL (~500×333) |
| `firstimage2` | - | 썸네일 이미지 URL (~150×100) |
| `cpyrhtDivCd` | - | 저작권 유형 |
| `overview` | - | 콘텐츠 개요 |
| `lDongRegnCd` / `lDongSignguCd` | - | 시도 / 시군구 코드 |
| `lclsSystm1` / `lclsSystm2` / `lclsSystm3` | - | 분류체계 코드 |

### 예시

```
GET /detailCommon2?serviceKey=인증키&numOfRows=10&pageNo=1&MobileOS=ETC&MobileApp=AppTest&_type=json&contentId=2815432
```

```json
{
  "response": {
    "header": { "resultCode": "0000", "resultMsg": "OK" },
    "body": {
      "items": {
        "item": [{
          "contentid": "2815432",
          "contenttypeid": "76",
          "title": "Wonju Sogeumsan Ulleong Bridge",
          "addr1": "12 Sogeumsan-gil, Wonju-si, Gangwon-do",
          "mapx": "127.8340575195",
          "mapy": "37.3646293574",
          "overview": "Sogeumsan Ulleong Bridge is approximately twice as long..."
        }]
      },
      "numOfRows": 1, "pageNo": 1, "totalCount": 1
    }
  }
}
```

---

## 9. 소개정보 조회 `detailIntro2` (상세정보2)

```
GET /detailIntro2
```

타입별 소개 정보(운영시간, 요금, 주차 등)를 조회한다. 타입마다 응답 필드가 다르다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `contentId` | ✅ | `2815432` | 콘텐츠 ID |
| `contentTypeId` | ✅ | `76` | 콘텐츠 타입 ID |

### Response — 타입별 주요 필드

**contentTypeId=76 (관광지)**

| 필드 | 설명 |
|------|------|
| `accomcount` | 수용인원 |
| `expagerange` | 체험가능연령 |
| `expguide` | 체험안내 |
| `infocenter` | 문의및안내 |
| `opendate` | 개장일 |
| `parking` | 주차시설 |
| `restdate` | 쉬는날 |
| `useseason` | 이용시기 |
| `usetime` | 이용시간 |

**contentTypeId=78 (문화시설)**

| 필드 | 설명 |
|------|------|
| `accomcountculture` | 수용인원 |
| `infocenterculture` | 문의및안내 |
| `parkingculture` | 주차시설 |
| `parkingfee` | 주차요금 |
| `restdateculture` | 쉬는날 |
| `usefee` | 이용요금 |
| `usetimeculture` | 이용시간 |
| `scale` | 규모 |
| `spendtime` | 관람소요시간 |

**contentTypeId=85 (행사/공연/축제)**

| 필드 | 설명 |
|------|------|
| `agelimit` | 관람가능연령 |
| `bookingplace` | 예매처 |
| `discountinfofestival` | 할인정보 |
| `eventstartdate` | 행사시작일 |
| `eventenddate` | 행사종료일 |
| `eventhomepage` | 행사홈페이지 |
| `eventplace` | 행사장소 |
| `playtime` | 공연시간 |
| `program` | 행사프로그램 |
| `sponsor1` / `sponsor1tel` | 주최자 정보 / 연락처 |
| `sponsor2` / `sponsor2tel` | 주관사 정보 / 연락처 |
| `subevent` | 부대행사 |
| `usetimefestival` | 이용요금 |

**contentTypeId=75 (레포츠)**

| 필드 | 설명 |
|------|------|
| `accomcountleports` | 수용인원 |
| `expagerangeleports` | 체험가능연령 |
| `infocenterleports` | 문의및안내 |
| `openperiod` | 개장기간 |
| `parkingfeeleports` | 주차요금 |
| `parkingleports` | 주차시설 |
| `reservation` | 예약안내 |
| `restdateleports` | 쉬는날 |
| `scaleleports` | 규모 |
| `usefeeleports` | 입장료 |
| `usetimeleports` | 이용시간 |

**contentTypeId=80 (숙박)**

| 필드 | 설명 |
|------|------|
| `accomcountlodging` | 수용가능인원 |
| `checkintime` | 입실시간 |
| `checkouttime` | 퇴실시간 |
| `chkcooking` | 객실내 취사여부 |
| `foodplace` | 식음료장 |
| `infocenterlodging` | 문의및안내 |
| `parkinglodging` | 주차시설 |
| `pickup` | 픽업서비스 |
| `roomcount` | 객실수 |
| `reservationlodging` | 예약안내 |
| `reservationurl` | 예약안내 홈페이지 |
| `roomtype` | 객실유형 |
| `scalelodging` | 규모 |
| `subfacility` | 부대시설 |

**contentTypeId=79 (쇼핑)**

| 필드 | 설명 |
|------|------|
| `fairday` | 장서는날 |
| `infocentershopping` | 문의및안내 |
| `opendateshopping` | 개장일 |
| `opentime` | 영업시간 |
| `parkingshopping` | 주차시설 |
| `restdateshopping` | 쉬는날 |
| `restroom` | 화장실 설명 |
| `saleitem` | 판매품목 |
| `scaleshopping` | 규모 |
| `shopguide` | 매장안내 |

**contentTypeId=82 (음식점)**

| 필드 | 설명 |
|------|------|
| `firstmenu` | 대표메뉴 |
| `infocenterfood` | 문의및안내 |
| `opendatefood` | 개업일 |
| `opentimefood` | 영업시간 |
| `parkingfood` | 주차시설 |
| `reservationfood` | 예약안내 |
| `restdatefood` | 쉬는날 |
| `scalefood` | 규모 |
| `seat` | 좌석수 |
| `smoking` | 금연/흡연여부 |
| `treatmenu` | 취급메뉴 |
| `lcnsno` | 인허가번호 |

**contentTypeId=77 (교통)**

| 필드 | 설명 |
|------|------|
| `chkcreditcardtraffic` | 신용카드가능여부 |
| `conven` | 편의시설 |
| `disablefacility` | 장애인편의시설 |
| `foreignerinfocenter` | 외국인 문의및안내 |
| `infocentertraffic` | 문의및안내 |
| `mainroute` | 주요노선 |
| `operationtimetraffic` | 운영시간 |
| `parkingtraffic` | 주차시설 |
| `restroomtraffic` | 화장실 |
| `shipinfo` | 여객선정보 |

### 예시

```
GET /detailIntro2?serviceKey=인증키&numOfRows=10&pageNo=1&MobileOS=ETC&MobileApp=AppTest&_type=json&contentId=2815432&contentTypeId=76
```

---

## 10. 반복정보 조회 `detailInfo2` (상세정보3)

```
GET /detailInfo2
```

타입별 반복 정보(할인, 시설 등)를 조회한다.  
숙박·여행코스 반복 정보는 국문 서비스만 제공된다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `contentId` | ✅ | `2815432` | 콘텐츠 ID |
| `contentTypeId` | ✅ | `76` | 콘텐츠 타입 ID |

### Response

| 필드 | 설명 |
|------|------|
| `contentid` | 콘텐츠 ID |
| `contenttypeid` | 콘텐츠 타입 ID |
| `infoname` | 항목 제목 |
| `infotext` | 항목 내용 |
| `serialnum` | 반복 일련번호 |
| `fldgubun` | 일련번호 |

### 예시

```
GET /detailInfo2?serviceKey=인증키&numOfRows=10&pageNo=1&MobileOS=ETC&MobileApp=AppTest&_type=json&contentId=2815432&contentTypeId=76
```

```json
{
  "response": {
    "header": { "resultCode": "0000", "resultMsg": "OK" },
    "body": {
      "items": {
        "item": [{
          "contentid": "2815432",
          "contenttypeid": "76",
          "serialnum": "0",
          "infoname": "Admission Fees",
          "infotext": "Adults 3,000 won / Youth 2,000 won / Children 1,500 won"
        }]
      },
      "numOfRows": 1, "pageNo": 1, "totalCount": 1
    }
  }
}
```

---

## 11. 이미지정보 조회 `detailImage2` (상세정보4)

```
GET /detailImage2
```

콘텐츠의 이미지 URL 목록을 조회한다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `contentId` | ✅ | `2815432` | 콘텐츠 ID |
| `imageYN` | - | `Y` | `Y`: 콘텐츠 이미지 / `N`: 음식점 메뉴 이미지 |
| `cpyrhtDivCd` | - | `Type1` | 저작권 유형 필터 (`Type1` / `Type3`) |

### Response

| 필드 | 설명 |
|------|------|
| `contentid` | 콘텐츠 ID |
| `imgname` | 이미지명 |
| `originimgurl` | 원본 이미지 URL (~500×333) |
| `smallimageurl` | 썸네일 이미지 URL (~160×100) |
| `serialnum` | 이미지 일련번호 |
| `cpyrhtDivCd` | 저작권 유형 |

### 예시

```
GET /detailImage2?serviceKey=인증키&numOfRows=10&pageNo=1&MobileOS=ETC&MobileApp=AppTest&_type=json&contentId=2815432&imageYN=Y
```

---

## 12. 다국어 관광정보 동기화 목록 조회 `areaBasedSyncList2`

```
GET /areaBasedSyncList2
```

콘텐츠 표출 여부 및 변경일자 기준으로 동기화 목록을 조회한다.

### Request

| 파라미터 | 필수 | 샘플 | 설명 |
|---------|------|------|------|
| `showflag` | - | `1` | `1`: 표출 / `0`: 비표출 |
| `modifiedtime` | - | `20250424` | 변경일자 (년 / 년월 / 년월일) |
| `arrange` | - | `C` | 정렬 구분 |
| `contentTypeId` | - | - | ContentTypeId 코드 참고 |
| `lDongRegnCd` | - | - | 시도 코드 |
| `lDongSignguCd` | - | - | 시군구 코드 (lDongRegnCd 필수) |
| `lclsSystm1` / `lclsSystm2` / `lclsSystm3` | - | - | 분류체계 코드 |

### Response

지역기반 관광정보 응답 필드와 동일 + 추가:

| 필드 | 설명 |
|------|------|
| `showflag` | 표출 여부 (`1`/`0`) |
| `oldContentid` | 이전 콘텐츠 ID |

---

## API 활용 흐름

```
1. 법정동코드 조회 (ldongCode2)
   → lDongRegnCd, lDongSignguCd 확보

2. 분류체계코드 조회 (lclsSystmCode2)
   → lclsSystm1 / lclsSystm2 / lclsSystm3 확보

3. 목록 조회 (contentid 획득)
   ├─ areaBasedList2     : 지역 기반
   ├─ locationBasedList2 : GPS 좌표 기반
   ├─ searchKeyword2     : 키워드 검색
   ├─ searchFestival2    : 행사/공연/축제 (날짜 기반)
   └─ searchStay2        : 숙박 (베니키아·한옥·굿스테이)

4. 상세정보 조회 (contentid 사용)
   ├─ detailCommon2  : 공통 정보 (제목, 주소, 개요)
   ├─ detailIntro2   : 소개 정보 (운영시간, 입장료 등 타입별 상이)
   ├─ detailInfo2    : 반복 정보 (할인, 시설 항목 등)
   └─ detailImage2   : 이미지 목록
```
