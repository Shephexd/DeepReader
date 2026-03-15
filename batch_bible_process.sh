#!/bin/bash

# --- 설정 ---
DB_PATH="DeepReader/Resources/Bible/BibleMaster.sqlite"
LOG_FILE="batch_process.log"

# 1. 처리해야 할 구절 목록 가져오기 (ai_insight가 없는 것들)
# ID, 권, 장, 절, 한글본문, 영문본문을 탭(|) 구분자로 가져옴
echo "🔍 처리 대기 중인 구절을 탐색합니다..."
TOTAL_REMAINING=$(sqlite3 "$DB_PATH" "SELECT count(*) FROM verses WHERE ai_insight = '' OR ai_insight IS NULL;")

if [ "$TOTAL_REMAINING" -eq 0 ]; then
    echo "✅ 모든 구절에 인사이트가 이미 존재합니다."
    exit 0
fi

echo "🚀 총 $TOTAL_REMAINING 구절에 대해 배치를 시작합니다."

# 2. 루프 실행
# 한 번에 100개씩 끊어서 처리 (안정성을 위해)
sqlite3 "$DB_PATH" "SELECT id, book_name_ko, chapter, verse, content_ko, content_en FROM verses WHERE ai_insight = '' OR ai_insight IS NULL LIMIT 100;" | while read -r line; do
    
    # 데이터 분리
    ID=$(echo "$line" | cut -d'|' -f1)
    BOOK=$(echo "$line" | cut -d'|' -f2)
    CHAP=$(echo "$line" | cut -d'|' -f3)
    VER=$(echo "$line" | cut -d'|' -f4)
    KO_TEXT=$(echo "$line" | cut -d'|' -f5)
    EN_TEXT=$(echo "$line" | cut -d'|' -f6)

    echo "--------------------------------------------------"
    echo "📦 Processing [$ID] $BOOK $CHAP:$VER..."

    # 3. Gemini에게 분석 요청 (프롬프트 구성)
    # -- JSON 형식을 요구하여 파싱을 쉽게 함
    PROMPT="성경 구절 분석가로서 다음 구절의 한국어(개역개정)-영어(KJV) 번역 차이와 신학적 의미를 분석해줘.
    [구절] $BOOK $CHAP:$VER
    [한글] $KO_TEXT
    [영어] $EN_TEXT
    
    응답은 반드시 아래 형식을 지켜줘:
    KEYWORDS: 단어1, 단어2, 단어3
    INSIGHT: (여기에 ✨ 제목과 🔹 불릿 포인트를 사용한 3문장 이내의 고품질 해설 작성)"

    # Gemini CLI 호출 (실제 환경의 명령어에 맞게 조정 가능)
    # 여기서는 gemini 명령어가 표준 입력을 지원한다고 가정하거나 인자로 전달
    RAW_RESPONSE=$(gemini "$PROMPT")

    # 4. 결과 파싱 (KEYWORDS와 INSIGHT 추출)
    KEYWORDS=$(echo "$RAW_RESPONSE" | grep "KEYWORDS:" | sed 's/KEYWORDS://' | xargs)
    INSIGHT=$(echo "$RAW_RESPONSE" | sed -n '/INSIGHT:/,$p' | sed 's/INSIGHT://' | xargs)

    if [ -n "$INSIGHT" ]; then
        # 5. SQLite 업데이트
        # 특수문자(따옴표 등) 처리를 위해 변수 바인딩 사용 권장되나 bash에서는 아래와 같이 처리
        # 싱글 쿼테이션(')을 두개('')로 치환하여 SQL 에러 방지
        SAFE_INSIGHT=$(echo "$INSIGHT" | sed "s/'/''/g")
        SAFE_KEYWORDS=$(echo "$KEYWORDS" | sed "s/'/''/g")

        sqlite3 "$DB_PATH" "UPDATE verses SET ai_insight = '$SAFE_INSIGHT', keywords = '$SAFE_KEYWORDS' WHERE id = $ID;"
        
        echo "✅ [$BOOK $CHAP:$VER] 업데이트 성공"
        echo "$(date): Success - $BOOK $CHAP:$VER" >> "$LOG_FILE"
    else
        echo "❌ [$BOOK $CHAP:$VER] 분석 결과 생성 실패"
        echo "$(date): Failed - $BOOK $CHAP:$VER" >> "$LOG_FILE"
    fi

    # API Rate Limit 준수를 위해 잠시 대기 (1.5초)
    sleep 1.5

done

echo "🎉 배치 작업(100개)이 완료되었습니다. 나머지 구절을 위해 스크립트를 다시 실행할 수 있습니다."
