import sqlite3
import re
import os
import unicodedata

# 설정
INPUT_TXT = "../../Downloads/개역한글판성경.txt"
OUTPUT_DB = "DeepReader/Resources/Bible/BibleMaster.sqlite"

def normalize(text):
    return unicodedata.normalize('NFC', text)

# 성경 책 이름 매핑 (약어 -> 풀네임)
# 파일 포맷 예: 창1:1, 출1:1, ...
RAW_BOOK_MAP = {
    "창": "창세기", "출": "출애굽기", "레": "레위기", "민": "민수기", "신": "신명기",
    "수": "여호수아", "삿": "사사기", "룻": "룻기", "삼상": "사무엘상", "삼하": "사무엘하",
    "왕상": "열왕기상", "왕하": "열왕기하", "대상": "역대상", "대하": "역대하",
    "스": "에스라", "느": "느헤미야", "에": "에스더", "욥": "욥기", "시": "시편",
    "잠": "잠언", "전": "전도서", "아": "아가", "사": "이사야", "렘": "예레미야",
    "애": "예레미야애가", "겔": "에스겔", "단": "다니엘", "호": "호세아", "욜": "요엘",
    "암": "아모스", "옵": "오바댜", "욘": "요나", "미": "미가", "나": "나훔",
    "합": "하박국", "습": "스바냐", "학": "학개", "슥": "스가랴", "말": "말라기",
    "마": "마태복음", "막": "마가복음", "눅": "누가복음", "요": "요한복음", "행": "사도행전",
    "롬": "로마서", "고전": "고린도전서", "고후": "고린도후서", "갈": "갈라디아서", "엡": "에베소서",
    "빌": "빌립보서", "골": "골로새서", "살전": "데살로니가전서", "살후": "데살로니가후서",
    "딤전": "디모데전서", "딤후": "디모데후서", "딛": "디도서", "몬": "빌레몬서", "히": "히브리서",
    "약": "야고보서", "벧전": "베드로전서", "벧후": "베드로후서", "요일": "요한일서", "요이": "요한이서",
    "요삼": "요한삼서", "유": "유다서", "계": "요한계시록"
}

BOOK_MAP = {normalize(k): normalize(v) for k, v in RAW_BOOK_MAP.items()}
ABBR_LIST = list(BOOK_MAP.keys())

def import_real_korean_bible():
    if not os.path.exists(OUTPUT_DB):
        print("❌ 기존 DB를 찾을 수 없습니다.")
        return

    conn = sqlite3.connect(OUTPUT_DB)
    cur = conn.cursor()

    # 1. 기존 데이터 백업 (KJV 영문 데이터 보존)
    cur.execute("SELECT book_name_ko, chapter, verse, content_en FROM verses")
    kjv_data = {}
    for row in cur.fetchall():
        kjv_data[f"{normalize(row[0])}_{row[1]}_{row[2]}"] = row[3]

    # 2. 테이블 비우기
    cur.execute("DELETE FROM verses")
    
    # 3. 개역한글 텍스트 파싱 및 삽입
    count = 0
    with open(INPUT_TXT, 'r', encoding='cp949', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            
            # 패턴: (책약어)(장):(절) (내용)
            match = re.match(r'^([가-힣]{1,2})(\d+):(\d+)\s+(.*)$', line)
            if match:
                abbr = normalize(match.group(1))
                chapter = int(match.group(2))
                verse = int(match.group(3))
                content_ko = match.group(4)
                
                if abbr in BOOK_MAP:
                    book_ko = BOOK_MAP[abbr]
                    testament = "Old" if ABBR_LIST.index(abbr) < 39 else "New"
                    
                    # 영문 매칭
                    content_en = kjv_data.get(f"{book_ko}_{chapter}_{verse}", "")
                    
                    cur.execute("""
                        INSERT INTO verses (testament, book_name_ko, chapter, verse, content_ko, content_en, ai_insight, keywords)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, (testament, book_ko, chapter, verse, content_ko, content_en, "", ""))
                    count += 1
                else:
                    print(f"⚠️ 매핑되지 않은 약어 발견: {abbr}")

    conn.commit()
    conn.close()
    print(f"✅ 완료! {count}개의 진짜 [개역한글] 구절이 임포트되었습니다.")

if __name__ == "__main__":
    import_real_korean_bible()
