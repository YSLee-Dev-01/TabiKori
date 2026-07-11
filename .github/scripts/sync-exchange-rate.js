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

function formatSearchDate(daysBefore) {
  const date = new Date();
  date.setDate(date.getDate() - daysBefore);

  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  const dd = String(date.getDate()).padStart(2, "0");
  return `${yyyy}${mm}${dd}`;
}

async function fetchJPYRate(searchDate) {
  const url = new URL("https://oapi.koreaexim.go.kr/site/program/financial/exchangeJSON");
  url.searchParams.set("authkey", process.env.EXCHANGE_API_KEY);
  url.searchParams.set("data", "AP01");
  if (searchDate) {
    url.searchParams.set("searchdate", searchDate);
  }

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`환율 API 요청 실패: ${response.status}`);
  }

  const items = await response.json();
  const jpyItem = items.find((item) => {
    if (item.result !== 1 || !item.cur_unit) {
      return false;
    }
    return parseCurrencyUnit(item.cur_unit).code === "JPY";
  });

  if (!jpyItem || !jpyItem.deal_bas_r) {
    return null;
  }

  const { scale: unitScale } = parseCurrencyUnit(jpyItem.cur_unit);
  const baseRate = Number(jpyItem.deal_bas_r.replace(/,/g, ""));

  return { baseRate, unitScale };
}

const MAX_ATTEMPTS = 3;

async function fetchJPYRateWithFallback() {
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt += 1) {
    const searchDate = attempt === 0 ? undefined : formatSearchDate(attempt);
    const jpy = await fetchJPYRate(searchDate);

    if (jpy) {
      console.log(`${attempt + 1}번째 시도 성공 (searchdate: ${searchDate ?? "오늘"})`);
      return jpy;
    }

    console.log(`${attempt + 1}번째 시도 데이터 없음 (searchdate: ${searchDate ?? "오늘"})`);
  }

  return null;
}

async function main() {
  const jpy = await fetchJPYRateWithFallback();

  if (!jpy) {
    throw new Error(`${MAX_ATTEMPTS}회 재시도했지만 JPY 환율 데이터를 찾을 수 없습니다`);
  }

  await admin.database().ref("TabiKori/exchangeRates").set({
    updatedAt: Date.now(),
    rates: {
      JPY: jpy
    }
  });

  console.log(`JPY 환율 업로드 완료 (baseRate: ${jpy.baseRate}, unitScale: ${jpy.unitScale})`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
