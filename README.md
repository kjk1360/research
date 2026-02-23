# Research Hub

개인 리서치 저장소. Claude가 수집/분류/분석한 정보를 체계적으로 관리합니다.

## 디렉토리 구조

```
~/research/
├── gaming/          # 게임 산업
│   ├── trends/      # 최신 동향, 트렌드
│   ├── market/      # 시장 분석, 매출, 유저 데이터
│   ├── competitors/ # 경쟁사/경쟁작 분석
│   └── tech/        # 기술 동향 (엔진, 플랫폼 등)
├── marketing/       # 마케팅
│   ├── strategies/  # 마케팅 전략, UA
│   ├── case-studies/# 성공/실패 사례 분석
│   └── analytics/   # 데이터 분석, KPI
├── creative/        # 크리에이티브
│   ├── design/      # 디자인 트렌드, UI/UX
│   ├── content/     # 콘텐츠 기획, 스토리텔링
│   └── tools/       # 제작 도구, AI 도구
├── finance/         # 금융/투자
│   ├── stocks/      # 주식 분석
│   ├── crypto/      # 크립토/블록체인
│   └── analysis/    # 종합 투자 분석
├── _reports/        # 종합 리포트 (분야 횡단)
└── _archive/        # 오래된 리서치 아카이브
```

## 파일 네이밍 규칙

`YYYY-MM-DD_주제_요약.md`

예시: `2026-02-22_unity6-performance-benchmark.md`

## 태그 시스템

각 리서치 파일 상단에 YAML frontmatter로 메타데이터를 기록합니다:

```yaml
---
date: 2026-02-22
tags: [mobile, casual, revenue]
sources: [센서타워, 앱애니]
confidence: high | medium | low
status: draft | final
---
```
