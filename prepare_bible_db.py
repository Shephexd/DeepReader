import os
import json
import sqlite3
import re
import unicodedata

# 설정
KOREAN_DIR = "DeepReader/Resources/Bible/"
ENGLISH_JSON = "DeepReader/Resources/Bible/verses-1769.json"
OUTPUT_DB = "DeepReader/Resources/Bible/BibleMaster.sqlite"

BOOK_MAPPING = {
    unicodedata.normalize('NFC', k): v for k, v in {
        "창세기": "Genesis", "출애굽기": "Exodus", "레위기": "Leviticus", "민수기": "Numbers", "신명기": "Deuteronomy",
        "여호수아": "Joshua", "사사기": "Judges", "룻기": "Ruth", "사무엘상": "1 Samuel", "사무엘하": "2 Samuel",
        "열왕기상": "1 Kings", "열왕기하": "2 Kings", "역대상": "1 Chronicles", "역대하": "2 Chronicles",
        "에스라": "Ezra", "느헤미야": "Nehemiah", "에스더": "Esther", "욥기": "Job", "시편": "Psalms",
        "잠언": "Proverbs", "전도서": "Ecclesiastes", "아가": "Song of Solomon", "이사야": "Isaiah",
        "예레미야": "Jeremiah", "예레미야애가": "Lamentations", "에스겔": "Ezekiel", "다니엘": "Daniel",
        "호세아": "Hosea", "요엘": "Joel", "아모스": "Amos", "오바댜": "Obadiah", "요나": "Jonah",
        "미가": "Micah", "나훔": "Nahum", "하박국": "Habakkuk", "스바냐": "Zephaniah", "학개": "Haggai",
        "스가랴": "Zechariah", "말라기": "Malachi", "마태복음": "Matthew", "마가복음": "Mark", "누가복음": "Luke",
        "요한복음": "John", "사도행전": "Acts", "로마서": "Romans", "고린도전서": "1 Corinthians",
        "고린도후서": "2 Corinthians", "갈라디아서": "Galatians", "에베소서": "Ephesians", "빌립보서": "Philippians",
        "골로새서": "Colossians", "데살로니가전서": "1 Thessalonians", "데살로니가후서": "2 Thessalonians",
        "디모데전서": "1 Timothy", "디모데후서": "2 Timothy", "디도서": "Titus", "빌레몬서": "Philemon",
        "히브리서": "Hebrews", "야고보서": "James", "베드로전서": "1 Peter", "베드로후서": "2 Peter",
        "요한일서": "1 John", "요한이서": "2 John", "요한삼서": "3 John", "유다서": "Jude", "요한계시록": "Revelation"
    }.items()
}

KEYWORD_MAP = {
    "태초": "Beginning", "하나님": "God", "천지": "Heaven & Earth", "창조": "Creation",
    "말씀": "The Word", "빛": "Light", "어둠": "Darkness", "사랑": "Love",
    "믿음": "Faith", "소망": "Hope", "은혜": "Grace", "진리": "Truth",
    "생명": "Life", "구원": "Salvation", "예수": "Jesus", "그리스도": "Christ",
    "성령": "Holy Spirit", "평강": "Peace", "기쁨": "Joy", "땅": "Earth"
}

def get_keywords(content):
    words = [en for ko, en in KEYWORD_MAP.items() if ko in content]
    return ", ".join(words[:3]) if words else "Spirit, Wisdom"

def create_db():
    if os.path.exists(OUTPUT_DB): os.remove(OUTPUT_DB)
    conn = sqlite3.connect(OUTPUT_DB)
    cur = conn.cursor()
    
    # ai_insight, keywords 컬럼 추가
    cur.execute("""
    CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testament TEXT,
        book_name_ko TEXT,
        book_name_en TEXT,
        chapter INTEGER,
        verse INTEGER,
        content_ko TEXT,
        content_en TEXT,
        ai_insight TEXT,
        keywords TEXT
    )""")
    
    cur.execute("CREATE TABLE book_info (book_index INTEGER PRIMARY KEY, name_ko TEXT, name_en TEXT, testament TEXT, chapter_count INTEGER)")
    
    with open(ENGLISH_JSON, 'r', encoding='utf-8') as f: kjv = json.load(f)
    files = sorted([f for f in os.listdir(KOREAN_DIR) if f.endswith('.txt') and not any(x in f for x in ['.processed', '.utf8'])])
    
    for idx, filename in enumerate(files):
        path = os.path.join(KOREAN_DIR, filename)
        testament = "Old" if filename.startswith("1-") else "New"
        raw_name = re.sub(r'^[12]-\d{2}', '', filename.replace('.txt', ''))
        book_ko = unicodedata.normalize('NFC', raw_name)
        book_en = BOOK_MAPPING.get(book_ko, "")
        
        max_chapter = 0
        with open(path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line: continue
                parts = line.split(None, 1)
                if len(parts) < 2: continue
                nums = re.findall(r'\d+', parts[0])
                if len(nums) < 2: continue
                chapter, verse = int(nums[-2]), int(nums[-1])
                content_ko = parts[1]
                content_en = kjv.get(f"{book_en} {chapter}:{verse}", "")
                
                # 초기 키워드 생성
                keywords = get_keywords(content_ko)
                
                cur.execute("INSERT INTO verses (testament, book_name_ko, book_name_en, chapter, verse, content_ko, content_en, ai_insight, keywords) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                           (testament, book_ko, book_en, chapter, verse, content_ko, content_en, "", keywords))
                max_chapter = max(max_chapter, chapter)
        
        cur.execute("INSERT INTO book_info (book_index, name_ko, name_en, testament, chapter_count) VALUES (?, ?, ?, ?, ?)", (idx + 1, book_ko, book_en, testament, max_chapter))
        
    conn.commit()
    conn.close()
    print(f"✅ Recreated DB with 'ai_insight' and 'keywords' columns.")

if __name__ == "__main__":
    create_db()
