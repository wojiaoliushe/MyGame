# MyGame 背包系统设计文档

> **版本**：1.0  
> **引擎**：Godot 4.6  
> **技术选型**：基于 [GLoot](https://github.com/peter-kish/gloot) 3.x 扩展；异形占格在二期通过 `PatternGridConstraint` 实现。  
> **读者**：后续使用 Cursor 按本文档分阶段实现的开发者/Agent。  
> **关联代码**：`scripts/player.gd`、`scripts/weapons/*`、`scripts/ui/weapon_pause_menu.gd`、`scenes/player/player.tscn`

---

## 1. 目标与非目标

### 1.1 目标

| 优先级 | 目标 |
|--------|------|
| P0 | 玩家拥有可交互的**网格背包**（暂停时打开），支持拖拽、矩形占格、旋转（Gloot `GridConstraint`） |
| P0 | 背包内武器类物品与运行时 **`Weapon` 场景**同步（战斗逻辑沿用现有 `SlashWeapon` / `ThrustWeapon` / `RangeWeapon`） |
| P1 | 背包状态可 **序列化/读档**（Gloot `serialize` / `deserialize`） |
| P2 | **异形占格**（L/T 等 pattern），替换矩形占位逻辑 |
| P3 | **邻接加成**（Backpack Hero 式，按 `tags` 相邻触发） |

### 1.2 非目标（本期不做）

- 多人同步背包
- 商店/NPC 交易完整 UI（可预留 `Inventory` 节点）
- 3D 背包或地面掉落物实体（二期以后）
- 修改 `addons/gloot/` 官方源码（扩展放在 `addons/mygame_inventory/`）

---

## 2. 技术决策摘要

| 决策 | 选择 | 理由 |
|------|------|------|
| 背包底座 | **GLoot 3.x** | 物品原型、转移、堆叠、网格 UI、存档成熟；避免自研整套框架 |
| 一期占格 | **矩形** `GridConstraint` | 官方支持，先打通战斗同步与暂停 UI |
| 二期占格 | 自研 **`PatternGridConstraint`** + fork **`CtrlPatternInventoryGrid`** | Gloot 矩形 + 四叉树无法表达 L 形空角；独立 addon 便于合并上游 |
| 战斗 | **不改** `Weapon` 继承体系 | 仅改「谁被 `instantiate`」 |
| 旧 UI | **废弃** `WeaponPauseMenu` 的 add_child 武器按钮 | 由背包 UI + `LoadoutWeaponSync` 替代 |

---

## 3. 架构总览

```
┌─────────────────────────────────────────────────────────────┐
│  UI 层                                                       │
│  BackpackPanel (CanvasLayer, PROCESS_MODE_ALWAYS)           │
│    └── CtrlInventoryGrid  →  Inventory (player_backpack)    │
│         （二期：CtrlPatternInventoryGrid）                    │
└───────────────────────────┬─────────────────────────────────┘
							│ constraint_changed / item_*
┌───────────────────────────▼─────────────────────────────────┐
│  桥接层                                                      │
│  LoadoutWeaponSync (Node on Player)                         │
│    读取 InventoryItem.weapon_scene → 重建 Player 下 Weapon   │
└───────────────────────────┬─────────────────────────────────┘
							│
┌───────────────────────────▼─────────────────────────────────┐
│  数据层 (GLoot)                                              │
│  ItemProtoset (JSON) → Inventory + GridConstraint           │
│  （可选 WeightConstraint / ItemSlot）                        │
└───────────────────────────┬─────────────────────────────────┘
							│
┌───────────────────────────▼─────────────────────────────────┐
│  战斗层（现有）                                               │
│  Sword / Spear / Poleaxe / FireBall …                       │
└─────────────────────────────────────────────────────────────┘
```

**数据流**：玩家拖动物品 → `GridConstraint` 更新占位 → `Inventory.constraint_changed` → `LoadoutWeaponSync` 全量同步 `Weapon` 子节点。

---

## 4. 目录与文件规划

### 4.1 新增目录（实施时创建）

```
addons/gloot/                          # 从 AssetLib 安装，勿改业务逻辑
addons/mygame_inventory/               # 二期：异形约束 + fork UI（一期可空目录占位）
resources/items/
  game_items.json                      # GLoot Protoset（JSON 资源）
scenes/ui/
  backpack_panel.tscn                  # 暂停背包界面
scripts/inventory/
  loadout_weapon_sync.gd               # 背包 → Weapon 同步
  backpack_save.gd                     # 可选：存档封装
scripts/ui/
  backpack_panel.gd                    # 打开/关闭、暂停、Esc
```

### 4.2 修改/废弃

| 文件 | 操作 |
|------|------|
| `scripts/ui/weapon_pause_menu.gd` | 一期末废弃或改为仅调用 `BackpackPanel.open()` |
| `scenes/ui/weapon_pause_menu.tscn` | 由 `backpack_panel.tscn` 替代 |
| `scenes/player/player.tscn` | 移除默认子节点 `Sword`/`FireBall`（改由同步器生成）；添加 `Backpack`、`LoadoutWeaponSync` |
| `scenes/main.tscn` | **前置条件**：若仓库缺失须先恢复；挂载 `BackpackPanel`、绑定 Player 背包 |

### 4.3 遵守仓库约定

见 `.cursor/rules/godot-gdscript.mdc`：`scenes/` 仅 `.tscn`，`scripts/` 仅 `.gd`，`snake_case` / `PascalCase` / 信号命名、`res://` 路径。

---

## 5. 物品数据（Protoset）

### 5.1 资源路径

`res://resources/items/game_items.json`（Godot 中创建 **JSON** 资源并指向该文件）。

### 5.2 原型 ID 命名

- 使用路径式 ID：`weapons/sword`、`weapons/spear`
- 公共字段放基类：`weapon_base`、`consumable_base`

### 5.3 一期字段规范（矩形 GridConstraint）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `inherits` | string | 否 | 继承原型 ID |
| `name` | string | 是 | 显示名 |
| `image` | string | 是 | `res://` 纹理路径，供 `get_texture()` |
| `size` | string | 武器建议 | `"Vector2i(w, h)"`，默认 1×1 |
| `rotated` | bool | 否 | 90° 旋转 |
| `weight` | number | 否 | 配合 `WeightConstraint` |
| `stack_size` / `max_stack_size` | number | 否 | 武器固定为 1 |
| `weapon_scene` | string | 武器必填 | 对应 `res://scenes/weapons/*.tscn` |
| `tags` | 见 5.5 | 否 | 邻接用，一期可只定义不计算 |

### 5.4 一期示例内容

```json
{
  "weapon_base": {
	"name": "武器",
	"weight": 2,
	"stack_size": 1,
	"max_stack_size": 1,
	"tags": ["weapon"]
  },
  "weapons/sword": {
	"inherits": "weapon_base",
	"name": "剑",
	"image": "res://assets/generated/pixel_sword_frame_0.png",
	"size": "Vector2i(1, 2)",
	"weapon_scene": "res://scenes/weapons/sword.tscn"
  },
  "weapons/poleaxe": {
	"inherits": "weapon_base",
	"name": "长柄斧",
	"image": "res://assets/generated/poleaxe_horizontal_strict_frame_0.png",
	"size": "Vector2i(2, 2)",
	"weapon_scene": "res://scenes/weapons/poleaxe.tscn"
  },
  "weapons/spear": {
	"inherits": "weapon_base",
	"name": "长矛",
	"image": "res://assets/generated/spear_horizontal_strict_frame_0.png",
	"size": "Vector2i(1, 3)",
	"rotated": "true",
	"weapon_scene": "res://scenes/weapons/spear.tscn"
  },
  "weapons/fire_ball": {
	"inherits": "weapon_base",
	"name": "火球",
	"image": "res://assets/generated/fireball_horizontal_right_frame_0.png",
	"size": "Vector2i(1, 1)",
	"weapon_scene": "res://scenes/weapons/fire_ball.tscn"
  }
}
```

### 5.5 二期预留：`pattern`（异形）

```json
"weapons/sword_l": {
  "inherits": "weapon_base",
  "pattern": [[1, 1], [1, 0]],
  "pattern_anchor": [0, 0],
  "image": "...",
  "weapon_scene": "..."
}
```

- `pattern`：矩阵，1 表示占格，0 表示空洞  
- `pattern_anchor`：锚点格（放置 origin）  
- 旋转：0–3，存于物品实例属性 `rotation_steps`（二期约束维护）

**注意**：一期 JSON 可不含 `pattern`；二期启用 `PatternGridConstraint` 后，含 `pattern` 的物品**不得**再依赖矩形 `size` 占位（`size` 仅作 UI 外接矩形估算）。

---

## 6. 场景节点设计

### 6.1 Player（`scenes/player/player.tscn`）

```
Player (CharacterBody2D) ← scripts/player.gd
├── Sprite2D
├── CollisionShape2D
├── Camera2D
├── Backpack (Inventory)                    # protoset = game_items.json
│   └── GridConstraint                      # size = Vector2i(5, 4) 可调
├── LoadoutWeaponSync (Node)                # scripts/inventory/loadout_weapon_sync.gd
│   export player_path = ".."
│   export backpack_path = "../Backpack"
└── (不再默认挂 Sword / FireBall 实例)
```

### 6.2 主场景（`scenes/main.tscn`）

```
Main (Node2D) ← scripts/main.gd
├── Player (实例)
├── … 怪物/UI …
└── BackpackPanel (CanvasLayer)             # scenes/ui/backpack_panel.tscn
	  layer 高优先级
	  process_mode = ALWAYS（子树继承设置）
```

### 6.3 背包 UI（`scenes/ui/backpack_panel.tscn`）

```
BackpackPanel (CanvasLayer) ← scripts/ui/backpack_panel.gd
├── ColorRect / Panel（半透明遮罩，可选）
└── MarginContainer
	  └── CtrlInventoryGrid                 # GLoot 控件
			inventory → Player/Backpack
			field_dimensions ≈ (48, 48)
			item_spacing = 2
```

### 6.4 暂停与输入（与现 `main.gd` 一致）

- **Esc**：若未 Game Over 且未暂停 → `BackpackPanel.open()`；若面板已打开 → `close()`
- 打开面板：`get_tree().paused = true`
- 关闭面板：`get_tree().paused = false`
- Game Over 时不响应 Esc 开背包（沿用 `main.gd` 的 `_is_game_over_ui_visible()`）

---

## 7. 脚本职责与 API

### 7.1 `LoadoutWeaponSync`（`scripts/inventory/loadout_weapon_sync.gd`）

**职责**：监听背包变化，在 Player 下维护 `Weapon` 子节点集合。

**配置**：

```gdscript
@export var player_path: NodePath
@export var backpack_path: NodePath
## 仅同步带 weapon_scene 的物品；同原型多件 → 多个 Weapon 实例
```

**连接信号**（在 `_ready`）：

- `backpack.item_added`
- `backpack.item_removed`
- `backpack.constraint_changed`

**核心方法**：

```gdscript
func sync_from_backpack() -> void:
	# 1. 删除 Player 下所有 Weapon 类型子节点（is Weapon）
	# 2. 遍历 backpack.get_items()
	# 3. path = item.get_property("weapon_scene", "")
	# 4. 若 path 非空且有效：player.add_child(load(path).instantiate())
```

**规则**：

- 每个 `InventoryItem` 实例对应**最多一个** `Weapon` 实例（按物品对象 identity，不是 prototype_id）
- 非武器物品（无 `weapon_scene`）不同步
- 不在 `_physics_process` 里同步，仅信号驱动

**可选 `class_name LoadoutWeaponSync`**：若与引擎无冲突可声明。

### 7.2 `BackpackPanel`（`scripts/ui/backpack_panel.gd`）

```gdscript
func open() -> void
func close() -> void
func toggle() -> void
```

- `open()`：`visible = true`，`get_tree().paused = true`，`_set_pause_immune_process(self)`（可参考现 `weapon_pause_menu.gd` 递归设置 `PROCESS_MODE_ALWAYS`）
- `close()`：反向
- 通过 `@export var player_backpack_path` 或 `@export var inventory: Inventory` 绑定数据

### 7.3 `BackpackSave`（可选，`scripts/inventory/backpack_save.gd`）

```gdscript
static func serialize_inventory(inv: Inventory) -> String:
	return JSON.stringify(inv.serialize())

static func deserialize_inventory(inv: Inventory, json_str: String) -> bool:
	var data = JSON.parse_string(json_str)
	if data is Dictionary:
		return inv.deserialize(data)
	return false
```

存档键名建议：`player_backpack`（与全局存档系统对接时由主存档模块调用）。

### 7.4 与 `main.gd` 的集成

- 将 `@onready var _weapon_pause_menu` 改为 `@onready var _backpack_panel: BackpackPanel`
- `_unhandled_input` 中 `KEY_ESCAPE` 调用 `_backpack_panel.open()` / 处理已打开时关闭
- `trigger_game_over()` 中隐藏背包面板（同现逻辑 `visible = false`）

---

## 8. GLoot 使用要点（实施清单）

### 8.1 安装

1. AssetLib 安装 GLoot，仅 `addons/gloot`
2. **项目 → 插件** 启用 GLoot
3. 确认 Godot 4.4+（项目 4.6）

### 8.2 编辑器操作

1. 创建 `game_items.json` 并赋给 `Inventory.protoset`
2. `GridConstraint` 作为 `Inventory` **子节点**
3. UI 使用 `CtrlInventoryGrid`，`inventory` 属性指向 Player 下 `Backpack`

### 8.3 代码片段（转移/创建）

```gdscript
# 创建
var item := backpack.create_and_add_item("weapons/sword")

# 指定格
var item2 := backpack.create_item("weapons/fire_ball")
grid.add_item_at(item2, Vector2i(0, 0))

# 转移到另一 Inventory（同 protoset）
if other.can_add_item(item):
	other.add_item(item)
```

### 8.4 双背包拖拽

两个 `CtrlInventoryGrid` 绑定不同 `Inventory`，**protoset 必须相同**。

---

## 9. 分阶段实施计划

开发时请**严格按阶段验收**，再进入下一阶段。

### 阶段 0：前置

- [ ] 恢复或创建 `scenes/main.tscn` 并配置 `project.godot` 的 `run/main_scene`
- [ ] 安装并启用 GLoot 插件
- [ ] 创建 `resources/items/game_items.json`

**验收**：编辑器可运行主场景，无脚本错误。

---

### 阶段 1：矩形背包 + UI（P0）

| 步骤 | 内容 |
|------|------|
| 1.1 | Player 下添加 `Inventory` + `GridConstraint(5,4)`，设置 protoset |
| 1.2 | 实现 `backpack_panel.tscn` + `backpack_panel.gd`，`CtrlInventoryGrid` 可拖拽 |
| 1.3 | `main.gd` Esc 打开/关闭背包；暂停生效 |
| 1.4 | 编辑器或 `_ready` 中放入 1–2 个测试物品 |

**验收**：

- 游戏中 Esc 打开网格 UI，可拖动、旋转（若 UI 支持）物品
- 暂停时玩家/怪物停止（与现逻辑一致）
- 物品图标与 `image` 一致

---

### 阶段 2：战斗同步（P0）

| 步骤 | 内容 |
|------|------|
| 2.1 | 实现 `LoadoutWeaponSync`，接信号 |
| 2.2 | 从 `player.tscn` 移除默认武器子节点 |
| 2.3 | 背包放入 `weapons/sword` 后，玩家可自动攻击怪物 |
| 2.4 | 移除背包内武器后，对应攻击消失 |

**验收**：

- 仅背包内武器生效；多件武器同时生效
- 无 `WeaponPauseMenu` 时功能不回归

---

### 阶段 3：替换旧暂停菜单 + 存档（P1）

| 步骤 | 内容 |
|------|------|
| 3.1 | 删除或停用 `WeaponPauseMenu` 的加剑按钮逻辑 |
| 3.2 | 实现 `BackpackSave` 并在合适时机 save/load（如局外/检查点） |
| 3.3 | Game Over 时背包关闭 |

**验收**：

- 存档重载后格子位置与物品一致
- Game Over 不能开背包

---

### 阶段 4：异形占格（P2）

| 步骤 | 内容 |
|------|------|
| 4.1 | 新建 `addons/mygame_inventory/pattern_grid_constraint.gd`（**复制** `grid_constraint.gd` 改造） |
| 4.2 | 用 **逐格占用表** `_cells: Dictionary` 替代四叉树矩形占位 |
| 4.3 | 实现 `get_footprint(item) -> Array[Vector2i]`，读 `pattern` + `rotation_steps` |
| 4.4 | fork `CtrlInventoryGrid` → `CtrlPatternInventoryGrid`，合法位置逐格高亮 |
| 4.5 | Player `Backpack`：**移除** `GridConstraint`，**仅保留** `PatternGridConstraint` |
| 4.6 | 更新 `game_items.json` 中至少一件 L 形测试武器 |

**验收**：

- L 形武器凹口可放 1×1 物品
- 旋转四类方向放置正确
- `LoadoutWeaponSync` 仍正常

**禁止**：同一 `Inventory` 上同时挂 `GridConstraint` 与 `PatternGridConstraint`。

---

### 阶段 5：邻接加成（P3）

| 步骤 | 内容 |
|------|------|
| 5.1 | Protoset 增加 `tags: ["melee", "fire"]` 等 |
| 5.2 | `AdjacencyBonusCalculator`：在 `constraint_changed` 时扫描四邻 |
| 5.3 | 结果写入 `Player` 或全局 `CombatModifiers`，`Weapon` 读倍率 |

**验收**：相邻「火 + 剑」时伤害或攻速按设计变化（数值可配置）。

---

## 10. 二期 `PatternGridConstraint` 设计要点

> 供阶段 4 直接实现，无需再改架构。

### 10.1 与 `GridConstraint` 的差异

| 项目 | GridConstraint | PatternGridConstraint |
|------|----------------|------------------------|
| 占位模型 | 外接矩形 + QuadTree | `Vector2i → InventoryItem` 字典 |
| `rect_free` | 矩形 | 遍历 footprint 每格 |
| `get_item_at(pos)` | 矩形查询 | 单格查询 |
| `get_item_size` | 真实占格 | **仅 UI 外接框**，不参与占位 |

### 10.2 最小 API（与 Grid 对齐，便于 fork UI）

```gdscript
class_name PatternGridConstraint
extends InventoryConstraint

func get_item_position(item: InventoryItem) -> Vector2i
func set_item_position(item: InventoryItem, pos: Vector2i) -> bool
func move_item_to(item: InventoryItem, pos: Vector2i) -> bool
func can_place_item(item: InventoryItem, pos: Vector2i, rotation_steps: int, ignore: InventoryItem = null) -> bool
func add_item_at(item: InventoryItem, pos: Vector2i) -> bool
func get_item_at(pos: Vector2i) -> InventoryItem
func rotate_item(item: InventoryItem) -> bool
func get_rotated_footprint(item: InventoryItem) -> Array[Vector2i]
```

### 10.3 物品实例属性

| 属性 | 说明 |
|------|------|
| `rotation_steps` | 0–3，实例级，可 `set_property` |
| `pattern` | 也可只存在 protoset，用 `get_property` 读取 |

---

## 11. 测试用例（手动）

### 11.1 背包 UI

1. 空背包 → 放入 2×2 斧 → 剩余格正确减少  
2. 放不下时 `create_and_add_item` 返回 `null`  
3. 拖出边界 → 回弹或取消  
4. Esc 切换暂停/恢复  

### 11.2 战斗同步

1. 仅火球 → 仅远程攻击  
2. 剑 + 矛 → 两种攻击并存  
3. 移出剑 → 挥砍停止  

### 11.3 存档

1. 物品在 (2,1) → 存档 → 读档 → 位置不变  

### 11.4 异形（阶段 4）

1. L 形占 (0,0)(1,0)(0,1)，(1,1) 可放 1×1  
2. 旋转后仍不穿透占格  

---

## 12. 风险与约束

| 风险 | 影响 | 缓解 |
|------|------|------|
| `main.tscn` 缺失 | 无法联调 | 阶段 0 必须完成 |
| `CanvasLayer` 拖拽偏移 | 图标与鼠标错位 | 背包 UI 放独立 `CanvasLayer`；参考 Gloot #251 |
| 升级 Gloot 冲突 | fork 文件合并失败 | 扩展仅在 `addons/mygame_inventory/` |
| 双约束并存 | 占位混乱 | 文档约定仅一种网格约束 |
| 多件同武器原型 | 平衡性 | 设计层允许；后续可加「同类唯一」规则 |
| `weapon_scene` 为空 | 静默无武器 | `sync` 时 `push_warning` |
| 暂停与怪物生成 | 刷怪 Timer 行为 | 确认 `Timer` 在暂停下是否停止；必要时 `process_mode` 与 main 一致 |

---

## 13. Cursor 开发时的提示词建议

复制以下块作为 Cursor 任务描述：

```
请阅读 docs/backpack-system-design.md，仅实现「阶段 N」。
遵守 .cursor/rules/godot-gdscript.mdc。
不修改 addons/gloot/ 内文件。
完成后列出改动的场景/脚本，并对照文档验收项自检。
```

---

## 14. 参考链接

- GLoot 仓库：https://github.com/peter-kish/gloot  
- GLoot 文档：`addons/gloot` 安装后见官方 `docs/`  
- 示例场景：`addons/gloot/examples/inventory_grid_transfer.tscn`  
- 现有武器基类：`scripts/weapons/weapon.gd`  
- 待替换 UI：`scripts/ui/weapon_pause_menu.gd`

---

## 15. 修订记录

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2026-06-01 | 初版：Gloot 矩形一期 + Pattern 二期 + 分阶段验收 |
