import csv
import sqlite3
import os

# 설정
VERSES_CSV = "Bible_Verses_Export.csv"
BOOK_INFO_CSV = "Bible_BookInfo_Export.csv"
OUTPUT_DB = "DeepReader/Resources/Bible/BibleMaster.sqlite"

def update_db_from_csv():
    # DB 백업 (선택사항)
    if os.path.exists(OUTPUT_DB):
        os.remove(OUTPUT_DB)
    
    conn = sqlite3.connect(OUTPUT_DB)
    cur = conn.cursor()
    
    # 테이블 생성
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
    
    # 1. 책 정보 로드
    with open(BOOK_INFO_CSV, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            cur.execute("INSERT INTO book_info (book_index, name_ko, name_en, testament, chapter_count) VALUES (?, ?, ?, ?, ?)",
                       (row['book_index'], row['name_ko'], row['name_en'], row['testament'], row['chapter_count']))
    
    # 2. 말씀 데이터 로드
    with open(VERSES_CSV, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            cur.execute("INSERT INTO verses (testament, book_name_ko, book_name_en, chapter, verse, content_ko, content_en, ai_insight, keywords) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                       (row['testament'], row['book_name_ko'], row['book_name_en'], row['chapter'], row['verse'], row['content_ko'], row['content_en'], "", ""))
    
    conn.commit()
    conn.close()
    print(f"✅ Recreated DB with '개역한글' data from CSV files.")

if __name__ == "__main__":
    update_db_from_csv()
