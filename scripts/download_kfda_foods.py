#!/usr/bin/env python3
"""
KFDA 식품 영양 정보 전체 다운로드 스크립트

식약처 공공데이터 API(FoodNtrCpntDbInfo02)에서 모든 식품 데이터를 다운로드하여 JSON 파일로 저장합니다.
API 키가 필요합니다: https://www.data.go.kr/data/15127578/openapi.do

사용법:
    python3 scripts/download_kfda_foods.py --api-key YOUR_API_KEY
    python3 scripts/download_kfda_foods.py --api-key YOUR_API_KEY --output Bodii/Resources/kfda_foods.json
    python3 scripts/download_kfda_foods.py --api-key YOUR_API_KEY --all  # 품목대표 필터 없이 전체 저장
"""

import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request
import urllib.error
from typing import Optional, List, Dict

BASE_URL = "https://apis.data.go.kr/1471000/FoodNtrCpntDbInfo02/getFoodNtrCpntDbInq02"
PAGE_SIZE = 100  # API 최대 한 번에 가져올 수
RATE_LIMIT_DELAY = 0.2  # API 호출 간 대기 시간 (초)

# 영양소 필드 매핑 (AMT_NUM → 의미)
# AMT_NUM1: 에너지(kcal), AMT_NUM3: 단백질(g), AMT_NUM4: 지방(g)
# AMT_NUM6: 탄수화물(g), AMT_NUM7: 당류(g), AMT_NUM8: 식이섬유(g)
# AMT_NUM13: 나트륨(mg)


def fetch_page(api_key, page_no, num_of_rows):
    # type: (str, int, int) -> dict
    """KFDA API에서 한 페이지의 음식 데이터를 가져옵니다."""
    other_params = urllib.parse.urlencode({
        "pageNo": str(page_no),
        "numOfRows": str(num_of_rows),
        "type": "json",
    })
    url = "{base}?serviceKey={key}&{params}".format(
        base=BASE_URL, key=api_key, params=other_params
    )

    req = urllib.request.Request(url)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read().decode("utf-8")
            if raw.strip().startswith("<"):
                raise Exception("API returned XML - check API key")
            data = json.loads(raw)
            return data
    except urllib.error.HTTPError as e:
        print("  HTTP Error {0}: {1}".format(e.code, e.reason))
        raise
    except urllib.error.URLError as e:
        print("  URL Error: {0}".format(e.reason))
        raise


def safe_float(value):
    # type: (Optional[str]) -> Optional[float]
    """문자열을 float로 안전하게 변환합니다. 쉼표 포함된 숫자도 처리."""
    if value is None or str(value).strip() == "":
        return None
    try:
        cleaned = str(value).strip().replace(",", "")
        return round(float(cleaned), 2)
    except (ValueError, TypeError):
        return None


def parse_food_item(item):
    # type: (dict) -> Optional[dict]
    """API 응답의 음식 아이템을 앱에서 사용할 형식으로 변환합니다."""
    food_cd = (item.get("FOOD_CD") or "").strip()
    food_nm = (item.get("FOOD_NM_KR") or "").strip()

    if not food_cd or not food_nm:
        return None

    # 칼로리가 없으면 스킵
    calories = safe_float(item.get("AMT_NUM1"))
    if calories is None:
        return None

    # 1인분 정보 파싱 (Z10500 필드: "900.000g" 형태)
    serving_size = None
    serving_unit = None
    z_field = item.get("Z10500")
    if z_field and str(z_field).strip():
        z_str = str(z_field).strip()
        # "900.000g" → 900.0, "g"
        import re
        match = re.match(r"^([\d,.]+)\s*(.*)$", z_str)
        if match:
            serving_size = safe_float(match.group(1))
            unit = match.group(2).strip()
            if unit:
                serving_unit = unit

    # serving_size 폴백: SERVING_SIZE 필드에서 숫자 추출
    if serving_size is None:
        srv = item.get("SERVING_SIZE", "")
        if srv:
            import re
            num_match = re.match(r"^([\d,.]+)", str(srv).strip())
            if num_match:
                serving_size = safe_float(num_match.group(1))

    return {
        "foodCd": food_cd,
        "name": food_nm,
        "calories": calories,
        "protein": safe_float(item.get("AMT_NUM3")),
        "fat": safe_float(item.get("AMT_NUM4")),
        "carbohydrates": safe_float(item.get("AMT_NUM6")),
        "sodium": safe_float(item.get("AMT_NUM13")),
        "fiber": safe_float(item.get("AMT_NUM8")),
        "sugar": safe_float(item.get("AMT_NUM7")),
        "servingSize": serving_size,
        "servingUnit": serving_unit,
        "groupName": (item.get("FOOD_CAT1_NM") or "").strip() or None,
        "makerName": (str(item.get("MAKER_NM") or "")).strip() or None
            if item.get("MAKER_NM") and str(item.get("MAKER_NM")).strip() != "None" else None,
    }


def download_all_foods(api_key, include_all=False):
    # type: (str, bool) -> List[dict]
    """모든 KFDA 음식 데이터를 다운로드합니다."""
    all_foods = []  # type: List[dict]
    page_no = 1
    total_count = None
    fetched_count = 0
    skipped_count = 0

    print("KFDA 음식 데이터 다운로드 시작...")
    print("API: {0}".format(BASE_URL))
    print("페이지 크기: {0}".format(PAGE_SIZE))
    if not include_all:
        print("필터: 품목대표(DB_CLASS_CM=01)만 저장")
    print()

    while True:
        retry_count = 0
        max_retries = 3

        while retry_count < max_retries:
            try:
                print("  페이지 {0} 요청 중...".format(page_no), end="", flush=True)
                data = fetch_page(api_key, page_no, PAGE_SIZE)

                header = data.get("header", {})
                result_code = header.get("resultCode", "")

                if result_code != "00":
                    result_msg = header.get("resultMsg", "Unknown error")
                    if result_code == "03":
                        print(" -> 데이터 끝")
                        return all_foods
                    elif result_code == "22":
                        print(" -> Rate limit! 60초 대기...")
                        time.sleep(60)
                        retry_count += 1
                        continue
                    else:
                        print(" -> API Error: [{0}] {1}".format(result_code, result_msg))
                        retry_count += 1
                        time.sleep(5)
                        continue

                body = data.get("body", {})

                if total_count is None:
                    total_count = body.get("totalCount", 0)
                    print(" (전체: {0}개)".format(total_count), end="")

                items = body.get("items", [])
                if isinstance(items, dict):
                    items = [items]
                elif not isinstance(items, list):
                    items = []

                fetched_count += len(items)

                page_foods = []
                for item in items:
                    # 품목대표만 필터링 (include_all이 아닌 경우)
                    if not include_all and item.get("DB_CLASS_CM") != "01":
                        skipped_count += 1
                        continue

                    food = parse_food_item(item)
                    if food:
                        page_foods.append(food)

                all_foods.extend(page_foods)
                pct = (fetched_count / total_count * 100) if total_count else 0
                print(" -> +{0}개 (저장: {1}, 진행: {2:.1f}%)".format(
                    len(page_foods), len(all_foods), pct
                ))

                if not items or fetched_count >= total_count:
                    print("\n다운로드 완료! 저장: {0}개 / 스킵: {1}개 / 총: {2}개".format(
                        len(all_foods), skipped_count, fetched_count
                    ))
                    return all_foods

                break

            except Exception as e:
                retry_count += 1
                if retry_count < max_retries:
                    wait_time = 5 * retry_count
                    print(" -> Error: {0}. {1}초 후 재시도...".format(e, wait_time))
                    time.sleep(wait_time)
                else:
                    print(" -> 최대 재시도 초과. 현재까지 {0}개 저장.".format(len(all_foods)))
                    return all_foods

        page_no += 1
        time.sleep(RATE_LIMIT_DELAY)

    return all_foods


def deduplicate_foods(foods):
    # type: (List[dict]) -> List[dict]
    """foodCd 기준으로 중복 제거합니다."""
    seen = set()  # type: set
    unique = []  # type: List[dict]
    for food in foods:
        food_cd = food.get("foodCd")
        if food_cd and food_cd not in seen:
            seen.add(food_cd)
            unique.append(food)
    return unique


def main():
    parser = argparse.ArgumentParser(
        description="KFDA 식품 영양 정보 전체 다운로드"
    )
    parser.add_argument(
        "--api-key",
        required=True,
        help="공공데이터포털 API 키 (https://www.data.go.kr 에서 발급)",
    )
    parser.add_argument(
        "--output",
        default="Bodii/Resources/kfda_foods.json",
        help="출력 JSON 파일 경로 (기본값: Bodii/Resources/kfda_foods.json)",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        default=False,
        help="품목대표 필터 없이 전체 저장 (25만개, 대용량 주의)",
    )
    args = parser.parse_args()

    # 출력 디렉토리 생성
    output_dir = os.path.dirname(args.output)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    # 다운로드
    foods = download_all_foods(args.api_key, include_all=args.all)

    if not foods:
        print("다운로드된 음식 데이터가 없습니다.")
        sys.exit(1)

    # 중복 제거
    foods = deduplicate_foods(foods)
    print("중복 제거 후: {0}개".format(len(foods)))

    # JSON 저장 (compact format)
    output_data = {
        "version": 1,
        "generatedAt": time.strftime("%Y-%m-%dT%H:%M:%S+0900"),
        "totalCount": len(foods),
        "foods": foods,
    }

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(output_data, f, ensure_ascii=False, indent=None, separators=(",", ":"))

    file_size = os.path.getsize(args.output)
    print("\n저장 완료: {0}".format(args.output))
    print("파일 크기: {0:.1f} MB".format(file_size / 1024 / 1024))
    print("총 음식 수: {0}개".format(len(foods)))


if __name__ == "__main__":
    main()
