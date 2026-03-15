import sqlite3
import time
import os

# 1. Google Generative AI 라이브러리 설치 필요: pip install google-generativeai
try:
    import google.generativeai as genai
except ImportError:
    print("라이브러리가 설치되지 않았습니다. 터미널에서 'pip install google-generativeai'를 실행해주세요.")
    exit(1)

# 2. 본인의 Gemini API 키를 입력하세요 (구글 AI 스튜디오에서 무료 발급 가능)
API_KEY = "YOUR_GEMINI_API_KEY" 
genai.configure(api_key=API_KEY)

# 빠르고 가성비 좋은 모델 선택
model = genai.GenerativeModel('gemini-1.5-flash')

DB_PATH = "DeepReader/Resources/Bible/BibleMaster.sqlite"

def generate_and_update_insights():
    if not os.path.exists(DB_PATH):
        print(f"❌ DB 파일을 찾을 수 없습니다: {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    # ai_insight가 비어있는 구절만 가져옵니다 (중간에 멈춰도 이어서 작업 가능)
    cur.execute("SELECT id, book_name_ko, chapter, verse, content_ko, content_en FROM verses WHERE ai_insight = '' OR ai_insight IS NULL")
    rows = cur.fetchall()
    
    print(f"🚀 총 {len(rows)}개의 구절에 대해 AI 인사이트 자동 생성을 시작합니다...")
    
    for idx, row in enumerate(rows):
        verse_id, book, chap, ver, ko_text, en_text = row
        
        prompt = f"""
        당신은 탁월한 성경 신학자이자 언어학자입니다. 
        다음 한국어 성경(개역한글)과 영어 성경(KJV) 구절을 비교하여 앱 사용자에게 제공할 짧고 깊이 있는 묵상 인사이트를 작성해주세요.
        
        [구절] {book} {chap}:{ver}
        [한국어] {ko_text}
        [영어] {en_text}
        
        다음 형식을 정확히 지켜서 응답해주세요:
        
        키워드: 영단어1, 영단어2, 영단어3
        인사이트: ✨ [해설 제목]
        
        (여기에 히브리어/헬라어 원어의 뉘앙스나 한국어-영어 번역의 차이점을 설명하는 3문장 이내의 깊은 해설을 작성. 줄바꿈과 🔹 기호를 적절히 사용하여 가독성을 높일 것.)
        """
        
        try:
            response = model.generate_content(prompt)
            text = response.text
            
            # 텍스트 파싱
            lines = text.strip().split('\n')
            keywords = "Spirit, Grace, Truth"
            insight = ""
            
            for line in lines:
                if line.startswith("키워드:"):
                    keywords = line.replace("키워드:", "").strip()
                elif line.startswith("인사이트:"):
                    # '인사이트:' 이후의 모든 텍스트를 가져옴
                    insight = text[text.find("인사이트:") + 5:].strip()
                    break
            
            if insight:
                cur.execute("UPDATE verses SET ai_insight = ?, keywords = ? WHERE id = ?", (insight, keywords, verse_id))
                conn.commit()
                print(f"[{idx+1}/{len(rows)}] ✅ {book} {chap}:{ver} 업데이트 완료")
            
            # API 속도 제한(Rate Limit) 방지를 위해 1.5초 대기
            time.sleep(1.5)
            
        except Exception as e:
            print(f"❌ {book} {chap}:{ver} 오류 발생: {e}")
            # 오류 발생 시 잠시 대기 후 다음 구절로 넘어감
            time.sleep(5)

    conn.close()
    print("🎉 모든 인사이트 생성이 완료되었습니다!")

if __name__ == "__main__":
    generate_and_update_insights()
