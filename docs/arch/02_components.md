# 2. コンポーネント

- **Health**(Node):`setup(max)` / `damage(n)`。`changed(hp, max)` と `died` を出す
- **Hitbox**(Area2D):`power` `direction` `delay_death` を持つ。`hit_once_per_activation` なら `activate()` 1回につき同じ相手へ1度だけ当たる。`guardable` なら盾で弾かれうる(主人公の一閃以外の踏み込み・燕返し)
- **Hurtbox**(Area2D):毎物理フレーム重なっている Hitbox を調べ、`try_hit()` が通れば `hurt(hitbox)` を出し、Hitbox 側の `landed(hurtbox)` も出す。`invincible` の間は調べない
  - `guard`(Callable)が設定されていて `guard.call(hitbox)` が true なら、`hurt` と `landed` の代わりに `guarded(hitbox)` を出す(盾鬼。ヒットストップも出ない)
  - 入った瞬間ではなく毎フレーム調べるのは、重なったまま無敵が切れたときにも当てるため
- ダメージ量やノックバックの解釈は持ち主(Player / Enemy)が `hurt` を受けて決める
