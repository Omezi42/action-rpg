# 2. コンポーネント

- **Health**(Node):`setup(max)` / `damage(n)`。`changed(hp, max)` と `died` を出す
- **Hitbox**(Area2D):`power` `direction` `delay_death` を持つ。`hit_once_per_activation` なら `activate()` 1回につき同じ相手へ1度だけ当たる
- **Hurtbox**(Area2D):毎物理フレーム重なっている Hitbox を調べ、`try_hit()` が通れば `hurt(hitbox)` を出し、Hitbox 側の `landed(hurtbox)` も出す。`invincible` の間は調べない
  - 入った瞬間ではなく毎フレーム調べるのは、重なったまま無敵が切れたときにも当てるため
- ダメージ量やノックバックの解釈は持ち主(Player / Enemy)が `hurt` を受けて決める
