#!/bin/bash

# --- 설정 ---
BATCH_SCRIPT="./batch_bible_process.sh"
DB_PATH="DeepReader/Resources/Bible/BibleMaster.sqlite"

# 실행 권한 보장
chmod +x "$BATCH_SCRIPT"

echo "=================================================="
echo "🛡️ DeepReader AI 인사이트 자동화 컨트롤러 시작"
echo "=================================================="

while true; do
    # 1. 잔여 구절 확인
    REMAINING=$(sqlite3 "$DB_PATH" "SELECT count(*) FROM verses WHERE ai_insight = '' OR ai_insight IS NULL;")
    
    if [ "$REMAINING" -eq 0 ]; then
        echo "✅ 축하합니다! 모든 성경 구절의 인사이트 생성이 완료되었습니다."
        break
    fi

    echo "📊 현재 남은 구절: $REMAINING 개"
    echo "🚀 다음 배치(100개)를 시작합니다..."

    # 2. 배치 스크립트 실행
    $BATCH_SCRIPT

    # 3. 배치가 끝난 후 시스템 및 API 과부하 방지를 위해 잠시 대기
    # (네트워크 불안정이나 API 할당량 회복을 위한 시간)
    echo "😴 배치가 완료되었습니다. 5초 후 다음 배치를 시도합니다..."
    sleep 5
    echo "--------------------------------------------------"
done

echo "🎉 모든 작업이 성공적으로 종료되었습니다."
