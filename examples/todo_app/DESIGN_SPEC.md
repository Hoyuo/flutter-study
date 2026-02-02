# TODO App Design Document

## Overview

Flutter Clean Architecture 기반 TODO 앱의 UI/UX 디자인 문서입니다.

- **디자인 파일**: `todo.pen`
- **테마**: Light / Dark 모드 지원
- **총 화면 수**: 7개 (모달 포함)

---

## Screen List

| # | Screen | Route | Description |
|---|--------|-------|-------------|
| 1 | TaskListPage | `/tasks` | 메인 화면 (Today Dashboard) |
| 2 | AllTasksPage | `/tasks/all` | 전체 Task 목록 + 검색/필터 |
| 3 | TaskEditPage | `/tasks/new`, `/tasks/:id/edit` | Task 생성/수정 |
| 4 | CategoryManagementPage | `/categories` | 카테고리 관리 |
| 5 | SettingsPage | `/settings` | 앱 설정 |
| 6 | Filter Bottom Sheet | (Modal) | Task 필터/정렬 |
| 7 | Category Create Modal | (Modal) | 카테고리 생성 |

---

## Navigation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        TaskListPage                              │
│                      (메인 - Today Dashboard)                    │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │
│  │ + Button │  │ Settings │  │ See all  │  │ Categories       │ │
│  │          │  │   Icon   │  │ (Tasks)  │  │ See all          │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┬─────────┘ │
└───────┼─────────────┼─────────────┼─────────────────┼───────────┘
        │             │             │                 │
        ▼             ▼             ▼                 ▼
┌──────────────┐ ┌──────────┐ ┌─────────────┐ ┌─────────────────────┐
│ TaskEditPage │ │ Settings │ │ AllTasksPage│ │CategoryManagementPage│
│  (새 Task)   │ │   Page   │ │             │ │                     │
└──────────────┘ └──────────┘ │ ┌─────────┐ │ │    ┌─────────────┐  │
                              │ │ Filter  │ │ │    │  + Button   │  │
                              │ │  Icon   │ │ │    └──────┬──────┘  │
                              │ └────┬────┘ │ │           │         │
                              └──────┼──────┘ └───────────┼─────────┘
                                     │                    │
                                     ▼                    ▼
                              ┌─────────────┐    ┌─────────────────┐
                              │Filter Bottom│    │ Category Create │
                              │   Sheet     │    │     Modal       │
                              └─────────────┘    └─────────────────┘
```

---

## Screen Details

### 1. TaskListPage (메인 화면)

**목적**: Today 중심의 대시보드, 빠른 Task 확인 및 접근

**구성 요소**:
- **Header**
  - 인사말 (Good morning/evening + 이모지)
  - "My Tasks" 타이틀
  - + 버튼 (새 Task 생성) - Purple
  - 설정 버튼 (Settings 이동) - Gray

- **Stats Row**
  - In Progress 카드 (활성 Task 수)
  - Completed 카드 (완료 Task 수)

- **Today's Tasks Section**
  - "Today's Tasks" 라벨 + "X remaining" 뱃지
  - Task 목록 (최대 5개)
  - 각 Task: 체크박스 + 제목 + 메타정보 (시간, 카테고리)

- **Categories Section**
  - "Categories" 라벨 + "See all" 링크
  - 카테고리 카드 (아이콘 + 이름 + Task 수)

**Actions**:
| Element | Action |
|---------|--------|
| + 버튼 | TaskEditPage (새 Task) |
| 설정 버튼 | SettingsPage |
| Task 항목 클릭 | TaskEditPage (수정) |
| Task 체크박스 | 완료 상태 토글 |
| "X remaining" 클릭 | AllTasksPage |
| Categories "See all" | CategoryManagementPage |
| Category 카드 클릭 | AllTasksPage (해당 카테고리 필터 적용) |

---

### 2. AllTasksPage (전체 Task 목록)

**목적**: 모든 Task 조회, 검색 및 필터링

**구성 요소**:
- **Header**
  - 뒤로가기 버튼
  - "All Tasks" 타이틀
  - Filter 버튼 (sliders-horizontal 아이콘)

- **Search Bar**
  - 검색 아이콘 + "Search tasks..." placeholder

- **Tasks List**
  - 전체 Task 목록 (스크롤)
  - 각 Task: 체크박스 + 제목 + 메타정보 (날짜, 우선순위)
  - 완료된 Task: 체크 아이콘 + 취소선

**Actions**:
| Element | Action |
|---------|--------|
| 뒤로가기 | TaskListPage로 복귀 |
| Filter 버튼 | Filter Bottom Sheet 표시 |
| 검색바 | 키워드 검색 |
| Task 항목 클릭 | TaskEditPage (수정) |
| Task 체크박스 | 완료 상태 토글 |

---

### 3. TaskEditPage (Task 생성/수정)

**목적**: 새 Task 생성 또는 기존 Task 수정

**구성 요소**:
- **Header**
  - 뒤로가기 버튼
  - "New Task" / "Edit Task" 타이틀
  - 저장 버튼 (check 아이콘)

- **Form Fields**
  - Task Title (텍스트 입력)
  - Description (멀티라인 텍스트)
  - Due Date (날짜 선택)
  - Priority (High/Medium/Low 선택)
  - Category (카테고리 선택)

- **Delete Button** (수정 모드에서만 표시)

**Actions**:
| Element | Action |
|---------|--------|
| 뒤로가기 | 변경사항 취소, 이전 화면으로 |
| 저장 버튼 | Task 저장 후 이전 화면으로 |
| Delete 버튼 | 확인 다이얼로그 후 삭제 |

---

### 4. CategoryManagementPage (카테고리 관리)

**목적**: 카테고리 CRUD 관리

**구성 요소**:
- **Header**
  - 뒤로가기 버튼
  - "Categories" 타이틀
  - + 버튼 (새 카테고리)

- **Categories List**
  - 카테고리 항목들
  - 각 항목: 색상 도트 + 아이콘 + 이름 + Task 수 + 더보기 메뉴

**Actions**:
| Element | Action |
|---------|--------|
| 뒤로가기 | TaskListPage로 복귀 |
| + 버튼 | Category Create Modal 표시 |
| 카테고리 항목 클릭 | AllTasksPage (해당 카테고리 필터) |
| 더보기 메뉴 | 수정/삭제 옵션 |

---

### 5. SettingsPage (설정)

**목적**: 앱 설정 관리

**구성 요소**:
- **Header**
  - 뒤로가기 버튼
  - "Settings" 타이틀

- **Appearance Section**
  - Theme 설정 (Light/Dark/System)

- **General Section**
  - Language 설정
  - Notifications 설정

- **About Section**
  - Version 정보

**Actions**:
| Element | Action |
|---------|--------|
| 뒤로가기 | TaskListPage로 복귀 |
| Theme 항목 | 테마 선택 다이얼로그 |
| Language 항목 | 언어 선택 |
| Notifications 항목 | 알림 설정 토글 |

---

### 6. Filter Bottom Sheet (필터/정렬 모달)

**목적**: Task 필터링 및 정렬 옵션 제공

**구성 요소**:
- **Handle Bar** (드래그 인디케이터)
- **Header**
  - "Filter & Sort" 타이틀
  - "Reset" 버튼

- **Status Filter**
  - All / Active / Done 선택

- **Sort By**
  - Date / Priority / Name 선택

- **Apply Button**

**Actions**:
| Element | Action |
|---------|--------|
| 바깥 영역 탭 / 아래로 스와이프 | 모달 닫기 |
| Reset | 필터 초기화 |
| Apply Filters | 필터 적용 후 모달 닫기 |

---

### 7. Category Create Modal (카테고리 생성 모달)

**목적**: 새 카테고리 생성

**구성 요소**:
- **Handle Bar** (드래그 인디케이터)
- **Header**
  - "New Category" 타이틀
  - X 버튼 (닫기)

- **Form Fields**
  - Category Name (텍스트 입력)
  - Color (색상 팔레트에서 선택)
  - Icon (아이콘 그리드에서 선택)

- **Create Button**

**Actions**:
| Element | Action |
|---------|--------|
| X 버튼 / 바깥 영역 탭 | 모달 닫기 |
| 색상 선택 | 해당 색상 활성화 |
| 아이콘 선택 | 해당 아이콘 활성화 |
| Create Category | 카테고리 생성 후 모달 닫기 |

---

## Design System

### Colors

#### Primary Colors
| Name | Hex | Usage |
|------|-----|-------|
| Purple | `#8B5CF6` | Primary action, selected state |
| Purple Light | `#8B5CF620` | Selected background |

#### Neutral Colors (Light Theme)
| Name | Hex | Usage |
|------|-----|-------|
| White | `#FFFFFF` | Background |
| Gray 100 | `#F4F4F5` | Card background, input field |
| Gray 400 | `#A1A1AA` | Placeholder, secondary text |
| Gray 500 | `#71717A` | Tertiary text |
| Gray 900 | `#18181B` | Primary text |

#### Neutral Colors (Dark Theme)
| Name | Hex | Usage |
|------|-----|-------|
| Black | `#0F0F10` | Background |
| Gray 800 | `#18181B` | Modal background |
| Gray 700 | `#27272A` | Card background, input field |
| Gray 600 | `#52525B` | Border, handle bar |
| Gray 500 | `#71717A` | Secondary text |
| White | `#FFFFFF` | Primary text |

#### Category Colors
| Color | Hex |
|-------|-----|
| Purple | `#8B5CF6` |
| Teal | `#14B8A6` |
| Pink | `#F472B6` |
| Orange | `#F59E0B` |
| Red | `#EF4444` |
| Indigo | `#6366F1` |

### Typography

| Style | Font | Size | Weight |
|-------|------|------|--------|
| Page Title | Plus Jakarta Sans | 28px | Bold (700) |
| Section Title | Plus Jakarta Sans | 20px | Bold (700) |
| Body | Inter | 16px | Medium (500) |
| Body Small | Inter | 15px | Regular (400) |
| Label | Inter | 14px | SemiBold (600) |
| Caption | Inter | 13px | Regular (400) |

### Spacing

| Size | Value | Usage |
|------|-------|-------|
| XS | 4px | Icon margins |
| SM | 8px | Tight spacing |
| MD | 12px | Default gap |
| LG | 16px | Section gap |
| XL | 20px | Large gap |
| 2XL | 24px | Page padding |

### Border Radius

| Size | Value | Usage |
|------|-------|-------|
| SM | 12px | Buttons, input fields |
| MD | 16px | Cards, large buttons |
| LG | 22px | Circular buttons |
| XL | 24px | Card containers |
| 2XL | 26px | Search bar |
| Modal | 32px | Bottom sheet top corners |

### Icons

- **Icon Set**: Lucide Icons
- **Size (Standard)**: 20-22px
- **Size (Small)**: 14-18px

---

## Interaction Patterns

### Navigation
- **Back Button**: 좌측 상단, 이전 화면으로 복귀
- **Action Button**: 우측 상단, 저장/필터 등 주요 액션

### Task Completion
- **Uncompleted**: 빈 원형 체크박스 (stroke only)
- **Completed**: 보라색 채워진 원 + 흰색 체크 아이콘
- **Completed Text**: 회색 + 취소선

### Selection States
- **Unselected**: Gray background (`#F4F4F5` / `#27272A`)
- **Selected**: Purple background (`#8B5CF6`) + White text

### Bottom Sheets
- **Handle Bar**: 상단 중앙, 40x4px rounded bar
- **Dismiss**: 바깥 영역 탭 또는 아래로 스와이프
- **Corner Radius**: 상단만 32px

### Buttons
- **Primary**: Purple background, white text, 56px height
- **Secondary**: Gray background, dark/light text
- **Icon Button**: 44-48px circular

---

## Responsive Considerations

- **Design Width**: 402px (기준)
- **Min Touch Target**: 44x44px
- **Safe Area**: 상단 20px, 하단 24px 패딩

---

## Accessibility

- **Color Contrast**: WCAG AA 준수
- **Touch Targets**: 최소 44x44px
- **Text Size**: 최소 13px
- **Interactive Feedback**: 선택 상태 명확히 표시

---

## File Structure in Pencil

```
todo.pen
├── Light Theme (y=0)
│   ├── TaskListPage (x=0)
│   ├── AllTasksPage (x=450)
│   ├── TaskEditPage (x=900)
│   ├── CategoryManagementPage (x=1350)
│   ├── SettingsPage (x=1800)
│   ├── Filter Bottom Sheet (x=2250)
│   └── Category Create Modal (x=2250, y=450)
│
└── Dark Theme (y=1000)
    ├── TaskListPage - Dark (x=0)
    ├── AllTasksPage - Dark (x=450)
    ├── TaskEditPage - Dark (x=900)
    ├── CategoryPage - Dark (x=1350)
    ├── SettingsPage - Dark (x=1800)
    ├── Filter Bottom Sheet - Dark (x=2250)
    └── Category Create Modal - Dark (x=2250, y=1450)
```
