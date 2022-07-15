# AgainAHK
[増井俊之氏](https://github.com/masui)のAgainのAutoHotKey実装です。<br/>
オリジナルはEmacs上で動作するマクロですが、AutoHotKeyで実装することにより、Windows上の全てのエディタ、アプリケーションで手軽にAgainを利用できます。

参考：https://github.com/masui/Again


## 使い方
### 必要なもの
* [AutoHotKey本体](https://www.autohotkey.com/)がインストールされていること

※ AutoHotKeyの`KeyHistory`を利用しているため、現状スクリプトをコンパイルした状態で使うことはできません。

### 起動と使い方
* `Again.ahk`をダブルクリックして実行します。
* 下記設定の`InvokeHotKey`で割り当てたホットキー(デフォルトは`Ctrl+l`)を入力すると、１秒間何も入力がない状態からその時点までのキー操作から繰り返し実行されます。



### 設定

#### ホットキーの指定
`Again.ini`の以下の部分でホットキーを設定してください。それぞれのコマンドの意味は下記の通りです。
```
InvokeHotKey=^l
```

| # | コマンド          | デフォルトHK | 機能概要                                 |
|---|-------------------|--------------|------------------------------------------|
| 1 | InvokeHotKey      | ^l           | 繰り返し実行                            |
| 2 | SuspendHotKey       | ^+l          | 本マクロの有効/無効切り替え              |

※#2は本家にはない機能ですが、Againマクロの有効・無効を切り替える機能を付けました。
ただし、PauseではなくSuspendのためタイマー自体は停止しません。これが気持ち悪い場合は、タスクトレイから手動で本スクリプトをPuaseするか終了してください。



#### ログ機能
利用状況を分析するために、ログ出力機能を付けています。<br/>
ログを出力するには、`Again.ini`の以下の部分を設定してください。
```
EnableLog=0
LogPath=Againlog.txt
```

`EnableLog`を1にすると、`LogPath`のファイルにログを出力します。ログファイルは絶対パスか相対パスで指定してください。相対パスの場合はAgain.ahkが存在するディレクトリを起点にします。

ログはCSV形式で、それぞれのカラムの意味は以下です。

| カラム    | 意味                                        | 例                         |
|-----------|---------------------------------------------|----------------------------|
| 第1カラム | 時刻                                        | 2021/07/17 01:01:01        |
| 第2カラム | 実行タイプ                                  | Reset or Repeat or Predict |
| 第3カラム | 自動タイプしたタイプ数                       | 3                          |
