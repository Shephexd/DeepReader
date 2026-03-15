import sqlite3

# AI(제가) 직접 작성한 고품질 프리미엄 인사이트 데이터
premium_insights = [
    # --- 창세기 1장 ---
    ("창세기", 1, 1, 
     "✨ [번역 인사이트]\n\n히브리어 원어 '베레쉬트(Bereshit)'는 단순히 시간의 출발점(Time zero)을 넘어, 모든 존재의 '근본'이자 '원리'를 의미합니다.\n\n🔹 영문 KJV의 'In the beginning'은 이를 명료하게 번역했습니다. 우연이 아닌 목적을 가진 웅장한 시작을 선포하는 문장입니다.", 
     "Beginning, Creation, God"),
    ("창세기", 1, 2, 
     "🔍 [원어 연구]\n\n'혼돈(Tohu)'과 '공허(Bohu)'는 형태도 없고 채워지지도 않은 절대적 무(無)이자 영적 흑암의 상태를 뜻합니다.\n\n🔹 이 절망적인 상태 위로 '하나님의 영(Spirit of God)'이 운행(Hovering)하십니다. 창조는 무질서(Chaos)에 생명과 질서(Cosmos)를 부여하는 위대한 사랑의 행위입니다.", 
     "Spirit, Void, Darkness"),
    ("창세기", 1, 3, 
     "🗣️ [말씀의 권위]\n\n성경에 처음으로 기록된 하나님의 '말씀(Said)'입니다. 고대 근동의 신화들이 신들의 피비린내 나는 전투로 세상을 창조했다고 묘사할 때, 성경은 오직 '말씀'만으로 세상이 지어졌음을 선포합니다.\n\n🔹 'Let there be light': 가장 간결하면서도 우주에서 가장 강력한 명령입니다.", 
     "Light, Word, Power"),
    ("창세기", 1, 4, 
     "⚖️ [구별의 시작]\n\n'나누사(Divided)'는 창조의 핵심 원리 중 하나입니다. 빛과 어둠의 분리는 단순한 물리적 현상을 넘어, 거룩함(Holy)의 본질인 '구별됨'을 시사합니다.\n\n🔹 영문 'that it was good'은 하나님의 선하신 목적에 완벽히 부합했음을 의미합니다.", 
     "Good, Divided, Light"),
    
    # --- 요한복음 1장 ---
    ("요한복음", 1, 1, 
     "📖 [철학과 복음의 만남]\n\n'말씀(Logos)'은 당시 헬라 철학에서 '우주를 지탱하는 이성이자 원리'였습니다. 요한은 이 단어를 빌려와 그 원리가 단순한 에너지가 아니라 '인격(예수 그리스도)'임을 헬라 세계에 선언했습니다.\n\n🔹 'The Word was God': 예수님의 신성을 가장 강력하게 증언하는 구절입니다.", 
     "The Word, God, Beginning"),
    ("요한복음", 1, 4, 
     "🌱 [생명의 차원]\n\n여기서 사용된 '생명'은 헬라어로 생물학적 생존(Bios)이 아닌, 영원하고 본질적인 생명(Zoe)을 의미합니다.\n\n🔹 영문 'the life was the light of men'은 그리스도 안에 있는 생명만이 인간의 영적 어둠을 밝히는 유일한 빛임을 강조합니다.", 
     "Life, Light, Men"),
    ("요한복음", 1, 5, 
     "⚔️ [영적 전투의 승리]\n\n'깨닫지 못하더라'의 헬라어 원어(Katalambano)는 '이해하다'는 뜻 외에도 '이겨내다, 압도하다'는 뜻을 가집니다.\n\n🔹 영문 KJV의 'comprehended it not'은 어둠이 빛의 찬란함을 결코 이길 수도, 덮어버릴 수도 없음을 보여주는 영광스러운 승리의 선포입니다.", 
     "Darkness, Comprehend, Victory"),
    ("요한복음", 1, 14, 
     "⛺ [성육신의 신비]\n\n'거하시매'의 원어적 의미는 '장막을 치다(Tabernacled)'입니다. 구약 시대 광야 성막에 임재하시던 하나님께서, 이제 인간의 육신이라는 장막을 입고 우리 가운데 오셨음을 뜻합니다.\n\n🔹 'The Word was made flesh': 기독교 신앙의 가장 위대하고 역설적인 신비입니다.", 
     "Flesh, Glory, Grace"),
     
    # --- 시편 23편 ---
    ("시편", 23, 1, 
     "🐑 [목자와 양]\n\n'여호와는 나의 목자시니' (The LORD is my shepherd). 양은 시력이 나쁘고 방어력이 없어 전적으로 목자에게 의존하는 동물입니다.\n\n🔹 다윗은 자신이 왕임에도 불구하고, 하나님 앞에서는 절대적으로 보호받아야 할 어린 양임을 고백하며 '부족함이 없다(I shall not want)'고 선언합니다.", 
     "Shepherd, Want, LORD"),
    ("시편", 23, 4, 
     "🕯️ [어둠 속의 동행]\n\n'사망의 음침한 골짜기(valley of the shadow of death)'는 인생의 가장 깊은 고난을 뜻합니다. 여기서 다윗의 어투가 '그(He)'에서 '주(Thou)'로 바뀝니다.\n\n🔹 고난의 한복판에서 하나님은 3인칭의 관찰자가 아니라, 나와 함께 걷는 2인칭의 동행자가 되십니다.", 
     "Shadow, Death, Fear Evil")
]

DB_PATH = "DeepReader/Resources/Bible/BibleMaster.sqlite"

def inject_premium_insights():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    count = 0
    for book, chap, ver, insight, keywords in premium_insights:
        cur.execute("""
            UPDATE verses 
            SET ai_insight = ?, keywords = ? 
            WHERE book_name_ko = ? AND chapter = ? AND verse = ?
        """, (insight, keywords, book, chap, ver))
        count += cur.rowcount
        
    conn.commit()
    conn.close()
    print(f"✅ Successfully injected {count} premium AI insights into the database.")

if __name__ == "__main__":
    inject_premium_insights()
