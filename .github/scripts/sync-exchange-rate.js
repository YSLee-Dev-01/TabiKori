const admin = require("firebase-admin");

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL
});

function parseCurrencyUnit(raw) {
  const match = raw.match(/^(.+)\((\d+)\)$/);
  if (!match) {
    return { code: raw, scale: 1 };
  }
  return { code: match[1], scale: Number(match[2]) };
}

async function fetchRates() {
  const url = new URL("https://oapi.koreaexim.go.kr/site/program/financial/exchangeJSON");
  url.searchParams.set("authkey", process.env.EXCHANGE_API_KEY);
  url.searchParams.set("data", "AP01");

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`환율 API 요청 실패: ${response.status}`);
  }

  const items = await response.json();
  const rates = {};

  for (const item of items) {
    if (item.result !== 1 || !item.cur_unit || !item.cur_nm || !item.deal_bas_r) {
      continue;
    }

    const { code: currencyCode, scale: unitScale } = parseCurrencyUnit(item.cur_unit);
    const baseRate = Number(item.deal_bas_r.replace(/,/g, ""));

    rates[currencyCode] = {
      currencyCode,
      currencyName: item.cur_nm,
      unitScale,
      baseRate
    };
  }

  return rates;
}

async function main() {
  const rates = await fetchRates();

  if (Object.keys(rates).length === 0) {
    throw new Error("파싱된 환율 데이터가 없습니다 (휴장일이거나 API 응답 오류)");
  }

  await admin.database().ref("exchangeRates").set({
    updatedAt: Date.now(),
    rates
  });

  console.log(`환율 ${Object.keys(rates).length}건 업로드 완료`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
