# User Journey Diagram - Zone Clock

## Business Logic Summary
Zone Clock helps users maintain focus through 90-minute work cycles with randomized micro-breaks (2-5 minutes), followed by 20-minute rest periods.

## User Journey Map

```mermaid
journey
    title Zone Clock 用户专注力管理之旅
    section 初次使用
      下载应用: 5: 用户
      查看引导: 5: 用户
      允许通知权限: 4: 用户
      配置个人偏好: 5: 用户
      {API: POST /api/users/onboarding}
    section 开始专注
      打开应用: 5: 用户
      点击开始专注: 5: 用户
      {API: POST /api/cycles/start}
      进入90分钟专注期: 5: 用户, 系统
      显示倒计时: 5: 系统
    section 微休息循环
      收到提示音(2-5分钟随机): 4: 系统
      {API: POST /api/breaks/micro/trigger}
      开始10秒微休息: 5: 系统
      继续专注: 5: 用户
      重复微休息循环: 4: 用户, 系统
    section 周期管理
      暂停当前周期: 3: 用户
      {API: PUT /api/cycles/{id}/pause}
      恢复继续: 4: 用户
      {API: PUT /api/cycles/{id}/resume}
      提前结束: 2: 用户
      {API: PUT /api/cycles/{id}/stop}
    section 大休息
      完成90分钟专注: 5: 用户, 系统
      {API: POST /api/breaks/long/start}
      进入20分钟休息: 5: 系统
      查看本轮统计: 5: 用户
      {API: GET /api/statistics/cycle/{id}}
      等待下轮开始: 4: 用户
    section 个性化配置
      进入设置页面: 5: 用户
      {API: GET /api/settings}
      调整专注时长(15-180分钟): 4: 用户
      {API: PUT /api/settings/focus-duration}
      调整休息时长(5-60分钟): 4: 用户
      {API: PUT /api/settings/break-duration}
      自定义提示音: 5: 用户
      {API: PUT /api/settings/sounds}
      切换勿扰模式: 4: 用户
      {API: PUT /api/settings/dnd}
    section 数据查看
      查看今日统计: 5: 用户
      {API: GET /api/statistics/today}
      查看历史记录: 4: 用户
      {API: GET /api/statistics/history}
      查看趋势分析: 4: 用户
      {API: GET /api/statistics/trends}
      同步跨设备数据: 5: 用户, 系统
      {API: POST /api/sync/trigger}
```

## Key User Touchpoints & API Mappings

### 核心流程映射
1. **用户启动专注** → `POST /api/cycles/start` → 进入专注状态
2. **系统触发微休息** → `POST /api/breaks/micro/trigger` → 短暂休息状态
3. **用户暂停/恢复** → `PUT /api/cycles/{id}/pause|resume` → 暂停/活动状态
4. **完成专注周期** → `POST /api/breaks/long/start` → 大休息状态
5. **配置个性化** → `PUT /api/settings/*` → 更新用户偏好
6. **查看统计** → `GET /api/statistics/*` → 数据展示
7. **跨设备同步** → `POST /api/sync/trigger` → 数据一致性

### 决策点标记
- **#REF-UJ-1**: 用户选择开始专注
- **#REF-UJ-2**: 系统随机触发微休息
- **#REF-UJ-3**: 用户决定暂停/继续
- **#REF-UJ-4**: 周期完成自动进入休息
- **#REF-UJ-5**: 用户自定义配置
- **#REF-UJ-6**: 查看数据分析
- **#REF-UJ-7**: 触发数据同步

## Business Logic Conservation Notes
- 每个用户动作都映射到具体的API调用
- 系统自动行为（微休息提醒）也通过API记录
- 状态转换通过API操作触发，保持逻辑一致性