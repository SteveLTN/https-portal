# HTTPS-PORTAL

HTTPS-PORTALは、[Nginx](http://nginx.org)、[Let's Encrypt](https://letsencrypt.org)、および
[Docker](https://www.docker.com)を利用した、完全自動化されたHTTPSサーバーです。
これを使用することで、追加の設定を1行だけ加えることで、既存のWebアプリケーションをHTTPS上で動作させることができます。

SSL証明書は、Let's Encryptから自動的に取得および更新されます。

Docker Hubページ：
[https://hub.docker.com/r/steveltn/https-portal/](https://hub.docker.com/r/steveltn/https-portal/)

**翻訳者注意:このドキュメントは 2023年11月26日(rev: 1a4f095494616591dd6c701f3a14f738a2e8ebe8)のコミットを元に翻訳しています。最新のドキュメントと相違がある可能性があります。必要に応じて、最新のドキュメントを参照してください。**

## 目次

- [HTTPS-PORTAL](#https-portal)
  - [目次](#目次)
  - [前提条件](#前提条件)
  - [試してみる](#試してみる)
  - [クイックスタート](#クイックスタート)
  - [特徴](#特徴)
    - [ローカルでのテスト](#ローカルでのテスト)
    - [リダイレクション](#リダイレクション)
    - [自動コンテナ発見](#自動コンテナ発見)
    - [Docker化されていないアプリとのハイブリッドセットアップ](#docker化されていないアプリとのハイブリッドセットアップ)
      - [ファイアウォール設定](#ファイアウォール設定)
    - [複数のドメイン](#複数のドメイン)
    - [複数のアップストリーム](#複数のアップストリーム)
    - [静的サイトの提供](#静的サイトの提供)
    - [他のアプリと証明書を共有する](#他のアプリと証明書を共有する)
    - [HTTPベーシック認証](#httpベーシック認証)
    - [アクセス制限](#アクセス制限)
    - [ロギング設定](#ロギング設定)
    - [デバッグ](#デバッグ)
    - [その他の設定](#その他の設定)
    - [国際化ドメイン名（IDN）](#国際化ドメイン名idn)
  - [高度な使用方法](#高度な使用方法)
    - [環境変数を通じてNginxを設定する](#環境変数を通じてnginxを設定する)
      - [Websocket](#websocket)
      - [DNS caching](#dns-caching)
      - [HSTS Header](#hsts-header)
      - [IPv6接続性](#ipv6接続性)
      - [その他のサーバーブロックレベルの設定](#その他のサーバーブロックレベルの設定)
    - [動的に設定を変更する](#動的に設定を変更する)
    - [Nginx設定ファイルを上書きする](#nginx設定ファイルを上書きする)
      - [単一サイトの設定のみを上書きする](#単一サイトの設定のみを上書きする)
      - [全てのサイトのデフォルト設定を上書きする](#全てのサイトのデフォルト設定を上書きする)
    - [秘密鍵の長さ/タイプを手動で設定する](#秘密鍵の長さタイプを手動で設定する)
  - [仕組み](#仕組み)
  - [Let's Encryptの利用制限について](#lets-encryptの利用制限について)
  - [トラブルシューティング](#トラブルシューティング)
    - [強制更新](#強制更新)
    - [データボリュームをリセットする](#データボリュームをリセットする)
  - [Credits](#credits)

## 前提条件

HTTPS-PORTALはDockerイメージとして提供されます。これを使用するには、以下の条件を満たすLinuxマシン（ローカルまたはリモートホスト）が必要です：

* 80番および443番ポートが利用可能で公開されていること。
* [Docker Engine](https://docs.docker.com/engine/installation/)がインストールされていること。さらに、[Docker Compose](https://docs.docker.com/compose/)の使用を強く推奨します。これにより操作が容易になります。当ドキュメントの例は主にDocker Composeフォーマットで示されています。
* 以下の例で使用するすべてのドメインが、そのマシンに解決されること。

Dockerに関する知識は必須ではありませんが、HTTPS-PORTALを使用するにはある程度の知識があると良いでしょう。

## 試してみる

以下の内容で任意のディレクトリに`docker-compose.yml`ファイルを作成してください：

```yaml
version: '3'

services:
  https-portal:
    image: steveltn/https-portal:1
    ports:
      - '80:80'
      - '443:443'
    environment:
      DOMAINS: 'example.com'
      # STAGE: 'production' # ステージングが正常に動作するまでは本番環境を使用しないでください
    volumes:
      - https-portal-data:/var/lib/https-portal

volumes:
    https-portal-data: # HTTPS-PORTALをアップグレードする際に再署名を避けるために推奨されます
```

同じディレクトリで`docker-compose up`コマンドを実行してください。
しばらくすると、[https://example.com](https://example.com)でウェルカムページが稼働します。

## クイックスタート

こちらはより実践的な例です：別のディレクトリで`docker-compose.yml`ファイルを作成してください：

```yaml
version: '3'

https-portal:
  image: steveltn/https-portal:1
  ports:
    - '80:80'
    - '443:443'
  restart: always
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress:80'
    # STAGE: 'production' # ステージングが機能するまで本番環境を使用しないでください
    # FORCE_RENEW: 'true'
  volumes: 
    - https-portal-data:/var/lib/https-portal

wordpress:
  image: wordpress

db:
  image: mariadb
  environment:
    MYSQL_ROOT_PASSWORD: '<a secure password>'

volumes:
  https-portal-data:
```

`docker-compose up -d`コマンドを実行してください。しばらくすると、[https://wordpress.example.com](https://wordpress.example.com)でWordPressが稼働します。

上記の例では、`https-portal`セクションの環境変数のみがHTTPS-PORTALに関する設定です。今回は追加のパラメーター`-d`を使用しました。これにより、`docker-compose.yml`で定義されたアプリケーションをバックグラウンドで実行するようDocker Composeに指示します。

注記：

- デフォルトでは`STAGE`は`staging`で、これはLet's Encryptからのテスト用（信頼されていない）証明書を意味します。
- `wordpress`はHTTPS-PORTALコンテナ内のWordPressコンテナのホスト名です。通常はWordPressコンテナのサービス名を使用できます。

## 特徴

### ローカルでのテスト

HTTPS-PORTALをローカルであなたのアプリケーションスタックと一緒にテストすることができます。

```yaml
https-portal:
  # ...
  environment:
    STAGE: local
    DOMAINS: 'example.com'
```


この操作を行うことで、HTTPS-PORTALは自己署名証明書を生成します。
この証明書はブラウザに信用される可能性は低いですが、docker-composeファイルのテストには使用できます。
あなたのアプリケーションスタックとの互換性があることを確認してください。

HTTPS-PORTALは、composeファイルで指定した`example.com`にのみ応答することに注意してください。
HTTPS-PORTALがあなたの接続に応答するようにするためには、次のいずれかを行う必要があります：

* `hosts`ファイルを変更して、`example.com`があなたのdockerホスト（127.0.0.1やその他のDockerホストを指すIPアドレス）に解決されるようにします。

または

* コンピューターやルーターにDNSMasqを設定します。この方法はより柔軟性があります。

または

* `docker-compose.yml`の`DOMAINS: 'example.com'`を`'mysite.lvh.me'`に変更します（lvh.meは任意の第二レベル名を127.0.0.1に解決するワイルドカードDNSエントリです）。これにより、https://mysite.lvh.me にアクセスできるようになります。

テストが完了したら、アプリケーションスタックをサーバーにデプロイできます。

### リダイレクション

HTTPS-PORTALはの迅速なリダイレクションのセットアップをサポートしています。

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'example.com => https://target.example.com' # 通常の「->」ではなく「=>」であることに注意してください
```

すべてのパスはターゲットにリダイレクトされます。例えば、`https://example.com/foo/bar` は307リダイレクトで `https://target.example.com/foo/bar` になります。

永続的なリダイレクションを望む場合は、環境変数 `REDIRECT_CODE=301` を設定してください。

一般的な使用例としては、`www.example.com` を `example.com` にリダイレクトすることがあります。DNSを設定し、`www.example.com` と `example.com` の両方がHTTPS-PORTALホストに解決されるようにして、以下のcomposeを使用してください：

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'www.example.com => https://example.com' # 通常の「->」ではなく「=>」であることに注意してください
```

### 自動コンテナ発見

**警告: この機能の使用は、絶対に必要な場合を除いて強くお勧めしません**。Dockerソケットをコンテナに公開する（`：ro`であっても）ことは、基本的にホストOSへのルートアクセス権をコンテナに与えることになります。それでも使用する場合は、ソースコードを慎重に確認してください。[詳細](https://dev.to/petermbenjamin/docker-security-best-practices-45ih)

HTTPS-PORTALは、Docker APIソケットがコンテナ内でアクセス可能である限り、同じホスト上で実行中の他のDockerコンテナを発見することができます。

これを可能にするためには、以下の`docker-compose.yml`を使用してHTTPS-PORTALを起動します。

```yaml
version: '2'

services:
  https-portal:
    # ...
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro # 危険、上記の警告を参照してください

```

そして、以下のように一つまたは複数のウェブアプリケーションを起動します：

```yaml
version: '2'

services:
  a-web-application:
    # ...
    environment:
      # tell HTTPS-PORTAL to set up "example.com"
      VIRTUAL_HOST: example.com
```

**注意点**: あなたのウェブアプリケーションは、HTTPS-PORTALと同じネットワーク内で作成される必要があります。

ここで、ウェブサービスをHTTPS-PORTALにリンクする**必要はありません**し、HTTPS-PORTALの環境変数`DOMAINS`に`example.com`を設定**すべきではありません**。

この機能により、同じホスト上に複数のウェブアプリケーションをデプロイすることができます。
HTTPS-PORTAL自体を再起動したり、ウェブアプリケーションを追加/削除する間に他のアプリケーションを中断することなく行えます。

ウェブサービスが複数のポートを公開している場合（ウェブサービスのDockerfileでポートが公開されている可能性があります）、環境変数`VIRTUAL_PORT`を使用してHTTPリクエストを受け入れるポートを指定します：


```yaml
a-multi-port-web-application:
  # ...
  expose:
    - '80'
    - '8080'
  environment:
    VIRTUAL_HOST: example.com
    VIRTUAL_PORT: '8080'
```

もちろん、コンテナ発見はENVで指定されたドメインと組み合わせて機能します：

```yaml
https-portal:
  # ...
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro # DANGEROUS, see the warning above
  environment:
    DOMAINS: 'example.com -> http://upstream'
```

### Docker化されていないアプリとのハイブリッドセットアップ

Dockerコンテナではなくホストマシン上で直接実行されるウェブアプリケーションは`host.docker.internal`で利用可能です。これは*Docker for Mac*や*Docker for Windows*でも動作します。

例えば、アプリケーションがホストマシンの8080ポートでHTTPリクエストを受け入れる場合、HTTPS-PORTALは以下のように起動できます：

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'example.com -> http://host.docker.internal:8080'
```

#### ファイアウォール設定 ####

[ufw](https://help.ubuntu.com/community/UFW)のようなファイアウォールを使用している場合、コンテナからDockerホストマシンへの通信を許可する必要があるかもしれません。
ufwがアクティブかどうかは、`ufw status`を実行して確認できます。

コマンドが`active`と返した場合、HTTPS-PORTALのコンテナIPからDockerホストIPのウェブアプリケーションがアクセス可能なポートへの8080ポートでの通信を許可するufwルールを追加します：

```
DOCKER_HOST_IP=`docker network inspect code_default --format='{{ .IPAM.Config}}' |awk '{print $2}'` # ネットワークがcode_defaultという名前であると仮定します。
HTTPS_PORTAL_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' code_https-portal_1` # コンテナの名前がcode_https-portal_1であると仮定します。
ufw allow from $HTTPS_PORTAL_IP to $DOCKER_HOST_IP port 8080
```

### 複数のドメイン

コンマで区切ることで複数のドメインを指定できます：

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress:80, gitlab.example.com -> http://gitlab'
```

また、各サイトのステージ（`local`、`staging`、または`production`）を指定することもできます。個々のサイトのステージはグローバルステージを上書きすることに注意してください：

```yaml
DOMAINS: 'wordpress.example.com -> http://wordpress #local, gitlab.example.com #staging'
```

### 複数のアップストリーム

ロードバランシングやHA（高可用性）のために、ドメインに複数のアップストリームを定義することが可能です。
パイプ区切りで追加のアップストリームを追加してください。各アップストリームにはカスタムパラメータを設定できます。


```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'wordpress.example.com -> http://wordpress1:80|wordpress2:80[weight=2 max_conns=100]
```

利用可能なパラメータについては、[Nginx Upstream-Module](http://nginx.org/en/docs/http/ngx_http_upstream_module.html#server)を参照してください。


### 静的サイトの提供

ウェブアプリケーションにリクエストを転送する代わりに、HTTPS-PORTALは直接（複数の）静的サイトを提供することもできます：

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'hexo.example.com, octopress.example.com'
  volumes:
    - https-portal-data:/var/lib/https-portal
    - /data/https-portal/vhosts:/var/www/vhosts
```

HTTPS-PORTALが起動されると、ホストマシン上の`/data/https-portal/vhosts`ディレクトリ内に、各仮想ホストのための対応するサブディレクトリが作成されます：

```yaml
/data/https-portal/vhosts
├── hexo.example.com
│  └── index.html
└── octopress.example.com
    └── index.html
```

このディレクトリ階層にあなた自身の静的ファイルを配置できますが、上書きされることはありません。ホームページとして提供される`index.html`が必要です。

### 他のアプリと証明書を共有する

任意のホストディレクトリを`/var/lib/https-portal`に[data volume](https://docs.docker.com/engine/userguide/dockervolumes/)としてマウントすることができます。

例えば：


```yaml
https-portal:
  # ...
  volumes:
    - /data/ssl_certs:/var/lib/https-portal
```

これで、証明書はホストの`/data/ssl_certs`に利用可能になります。


### HTTPベーシック認証

HTTPベーシック認証は簡単に設定できます。ウェブサイトをオンラインにはしたいが、準備が整うまで一般公開したくない場合に便利です。

docker-composeファイルでの設定方法：


```yaml
https-portal:
  # ...
  environment:
    DOMAINS: 'username:password@example.com -> <upstream>'
```

### アクセス制限

**注意：Docker for MacやDocker for Windowsでは、アクセス制限が意図したとおりに機能しない場合があります。これらのシステムでは、Dockerは基本的にVM（仮想マシン）内で実行されるため、リクエスト元のIPはプロキシサービスのIPになります。**

IPアクセス制限を有効にして、ウェブサイトを保護することができます。環境変数 `ACCESS_RESTRICTION` を使用して全体的な制限を指定することができます。加えて、各ウェブサイトに個別の制限を設けることも可能です。

全体的な制限を使用した例：


```yaml
https-portal:
  # ...
  environment:
    ACCESS_RESTRICTION: "1.2.3.4/24 4.3.2.1"
```

個別の制限を使用した例：

```yaml
https-portal:
  # ...
  environment:
    DOMAINS: "[1.2.3.4/24] a.example.com -> <upstream> , [1.2.3.4/24 4.3.2.1] b.example.com"
```

自動発見の例：

```yaml
https-portal:
  # ...
my_app:
  image: ...
  environment:
    VIRTUAL_HOST: "[1.2.3.4] example.com"
```

有効なIP値については、[Nginx allow](http://nginx.org/en/docs/http/ngx_http_access_module.html#allow)を参照してください。

### ロギング設定

デフォルトではNginxのアクセスログは書き込まれず、エラーログはstdoutに書き込まれ、Dockerによってキャプチャされます。これらを設定するいくつかのオプションがあります：

* エラーログ/アクセスログをstdout/stderrにリダイレクトする：
  
  ```yaml
  https-portal:
    # ...
    environment:
      ERROR_LOG: stdout
      ACCESS_LOG: stderr
  ```

* ログをデフォルトの場所に書き込む：

  ```yaml
  https-portal:
    # ...
    environment:
      ERROR_LOG: default
      ACCESS_LOG: default
    volumes:
      - https-portal-data:/var/lib/https-portal
      - /path/to/log/directory:/var/log/nginx/
      - /path/to/logrotate/state/directory:/var/lib/logrotate/
  ```

  デフォルトのログファイルのパスは `/var/log/nginx/access.log` と `/var/log/nginx/error.log` です。

  デフォルトの場所 `/var/log/nginx/*.log` にあるログファイルは毎日ローテーションされます。
  HTTPS-PORTALは最大30個のログファイルを保持し、2日以上経過したファイルは圧縮されます
  （現在の日と前日のログはプレーンテキストで利用可能で、それ以前のものは圧縮されます）。

  ログローテーションの設定を変更したい場合は、`/etc/logrotate.d/nginx`を上書きできます。

* カスタムの場所にログを書き込む：

  ```yaml
  https-portal:
    # ...
    environment:
      ERROR_LOG: /var/log/custom-logs/error.log
      ACCESS_LOG: /var/log/custom-logs/access.log
    volumes:
      - https-portal-data:/var/lib/https-portal
      - /path/to/log/directory:/var/log/custom-logs/
  ```

  この場合、自動的なログローテーションは行われないことに注意してください。

* その他の環境変数：

  ロギングに関する他の設定可能な環境変数もあります：

  * `ACCESS_LOG_BUFFER` - アクセスログのバッファサイズを制御します。例：16k。
  * `ERROR_LOG_LEVEL` - エラーログのレベルを制御します。デフォルト値は `error` です。

### デバッグ

環境変数 `DEBUG=true` を設定すると、ドメイン解析に関するより詳細な情報が表示されます。例えば：

```
DEBUG: name:'example.com' upstreams:'' redirect_target:''
```

### その他の設定

デフォルトでは、HTTPS-PORTALは証明書の有効期限の約30日前に証明書を更新します。これをカスタマイズするには：
```
RENEW_MARGIN_DAYS=30
```

### 国際化ドメイン名（IDN）

ドメインにASCII以外の文字が含まれている場合は、HTTPS-PORTALを使用する前に[ASCII互換エンコーディング（ACE）形式に変換](https://www.verisign.com/en_US/channel-resources/domain-registry-products/idn/idn-conversion-tool/index.xhtml)してください。

## 高度な使用方法

### 環境変数を通じてNginxを設定する

Nginxのデフォルトパラメータを変更する必要がある場合、Nginxを設定するために使用できる追加の環境変数がいくつかあります。
これらは通常 `nginx.conf` に設定するオプションに対応しています。
利用可能なパラメータとそのデフォルト値は以下の通りです：

```
INDEX_FILES=index.html                  # 探索するインデックスファイル名のスペース区切りリスト
WORKER_PROCESSES=1
WORKER_CONNECTIONS=1024
KEEPALIVE_TIMEOUT=65
GZIP=on                                 # 'off'にすることもできます（クオートが必要です）
SERVER_TOKENS=off
SERVER_NAMES_HASH_MAX_SIZE=512
SERVER_NAMES_HASH_BUCKET_SIZE=32        # CPUに基づいて32または64にデフォルト設定されます
CLIENT_MAX_BODY_SIZE=1M                 # 0はリクエストボディサイズのチェックを無効にします
PROXY_BUFFERS="8 4k"                    # プラットフォームに応じて4kまたは8k
PROXY_BUFFER_SIZE="4k"                  # プラットフォームに応じて4kまたは8k
RESOLVER="カスタムソルバー文字列"
PROXY_CONNECT_TIMEOUT=60;
PROXY_SEND_TIMEOUT=60;
PROXY_READ_TIMEOUT=60;
ACCESS_LOG=off;
ACCESS_LOG_INCLUDE_HOST=off;            # アクセスログにvhostを含める（goaccess用 => log-format=VCOMBINEDを使用）
REDIRECT_CODE=307                       # 1.20.1まではデフォルトで301でした

```

#### Websocket

追加することができます
```
WEBSOCKET=true
```

HTTPS-PORTALがWEBSOCKET接続をプロキシするように設定します。


#### DNS caching

nginxのDNSキャッシュを回避するために、動的アップストリームを有効にする

```
RESOLVER="127.0.0.11 ipv6=off valid=30s"
DYNAMIC_UPSTREAM=true
```

#### HSTS Header

以下の環境変数を使用して、HSTSヘッダーを設定できます。

**警告:** 希望の高いmax_age値に設定する前に、低い値でテストしてください。一度このヘッダーを送信すると、訪れたすべてのクライアントはHTTPへのダウングレードを拒否します。その結果、ウェブサイトをHTTPにフォールバックすることは不可能になります。

```
HSTS_MAX_AGE=60  # in seconds
```

#### IPv6接続性

**注意:** IPv6はLinuxホストでのみサポートされています。

以下の変数を使用してIPv6接続を有効にできます：

```
LISTEN_IPV6=true
```
#### その他のサーバーブロックレベルの設定

各ドメインに追加の`server`ブロックレベルの設定を追加できます：

```yaml
  environment:
    ...
    CUSTOM_NGINX_SERVER_CONFIG_BLOCK: add_header Strict-Transport-Security "max-age=60" always;
```

また、複数行にすることもできます：

```yaml
  environment:
    ...
    CUSTOM_NGINX_SERVER_CONFIG_BLOCK: |
    	add_header Strict-Transport-Security "max-age=60" always;
    	auth_basic "Password";	
```
変数を使用する場合、それらを$でエスケープする必要があります：

```yaml
  environment:
    ...
    CUSTOM_NGINX_GLOBAL_HTTP_CONFIG_BLOCK: |
        limit_req_zone $$binary_remote_addr zone=one:10m rate=1000r/m;
```

`CUSTOM_NGINX_SERVER_CONFIG_BLOCK`は、「環境変数を通じてNginxを設定する」セクションに記載されている他のすべての設定ブロックの後に挿入されますが、他の設定と競合する可能性があります。

全ての設定に適用されるグローバルな`CUSTOM_NGINX_SERVER_CONFIG_BLOCK`に加えて、特定のサイトの設定ファイルにのみ挿入される`CUSTOM_NGINX_<大文字とアンダースコアで区切られたドメイン名>_CONFIG_BLOCK`があります。**例えば**、`example.com`にのみ特定の変更を加えるには、環境変数`CUSTOM_NGINX_EXAMPLE_COM_CONFIG_BLOCK`を作成します。

```
# generated Nginx config:
server {
	listen 443 ssl http2;
	... # (other configurations)
	<%= CUSTOM_NGINX_SERVER_CONFIG_BLOCK %>
	<%= CUSTOM_NGINX_<DOMAIN_NAME>_CONFIG_BLOCK %>
	location / {
		...
	}
}
```

変数`CUSTOM_NGINX_GLOBAL_HTTP_CONFIG_BLOCK`および`CUSTOM_NGINX_SERVER_PLAIN_CONFIG_BLOCK`は、Nginxのステートメントをグローバルな`http`ブロックや平文（非SSL）の`server`ブロックに追加するために使用できます。

まれに`/.well-known/acme-challenge/`のリクエスト処理を変更したい場合は、`ACME_CHALLENGE_BLOCK`を設定することでデフォルトの設定が上書きされます。詳細は[Nginx設定テンプレート](https://github.com/SteveLTN/https-portal/tree/master/fs_overlay/var/lib/nginx-conf)をご覧ください。

### 動的に設定を変更する

環境変数は、ファイル`/var/lib/https-portal/dynamic-env`の変更を通じて動的に上書きされることができます。ファイルの名前と内容は、それぞれ環境変数の名前と内容を作成します。最後の変更から約1秒後、変更された設定が反映されます。これにより、ダウンタイムなしで設定を変更することが可能です。

### Nginx設定ファイルを上書きする

デフォルトのnginx設定を上書きするには、有効な`server`ブロックを含むnginx.confの設定セグメントを提供します。カスタムnginx設定は[ERB](http://www.stuartellis.eu/articles/erb/)テンプレートであり、使用前にレンダリングされます。

単一サイトの設定のみ、または全てのサイトの設定を上書きすることができます。

#### 単一サイトの設定のみを上書きする

この場合、`<your-domain>.conf.erb`と`<your-domain>.ssl.conf.erb`を提供します。前者はLet's Encryptからの所有権検証とHTTPS URLへのリダイレクトを担当し、後者はHTTPS接続を処理します。

例えば、`my.example.com`のHTTPSおよびHTTP設定の両方を上書きするには、HTTPS-PORTALを以下のように起動します：

```yaml
https-portal:
  # ...
  volumes:
    - https-portal-data:/var/lib/https-portal
    - /path/to/http_config:/var/lib/nginx-conf/my.example.com.conf.erb:ro
    - /path/to/https_config:/var/lib/nginx-conf/my.example.com.ssl.conf.erb:ro
```

[このファイル](https://github.com/SteveLTN/https-portal/blob/master/fs_overlay/var/lib/nginx-conf/default.conf.erb) と [このファイル](https://github.com/SteveLTN/https-portal/blob/master/fs_overlay/var/lib/nginx-conf/default.ssl.conf.erb) は、HTTPS-PORTALによって使用されるデフォルトの設定ファイルです。
これらのファイルをコピーして開始するのが良いでしょう。変数をそのまま使用することも、ドメインやアップストリームなどをハードコードすることもできます。

別の例は [こちら](/examples/custom_config) で見ることができます。

#### 全てのサイトのデフォルト設定を上書きする

すべてのサイトで使用されるNginx設定を作成したい場合、`/var/lib/nginx-conf/default.conf.erb` や `/var/lib/nginx-conf/default.ssl.conf.erb` を上書きすることができます。これらのファイルは、サイト固有の設定ファイルが提供されていない場合、各サイトに適用されます。

設定ファイルがすべてのサイトで使用されるため、ファイル内の変数をそのまま使用し、何もハードコードしないでください。

### 秘密鍵の長さ/タイプを手動で設定する

デフォルトでは、HTTPS-PORTALは`2048`ビット長のRSA秘密鍵を生成します。
しかし、`NUMBITS`環境変数を通じてRSA秘密鍵の長さ（`openssl genrsa`コマンドの`numbits`）を手動で設定することができます。

```yaml
https-portal:
  # ...
  environment:
    NUMBITS: '4096'
```

また、[Mozillaによって推奨されている](https://wiki.mozilla.org/Security/Server_Side_TLS#Modern_compatibility)ように、`CERTIFICATE_ALGORITHM`環境変数を`prime256v1`に設定することもできます。ただし、この設定は一部の古いクライアント/システムが接続できなくなることに注意してください。

これらの設定は新しく生成された鍵にのみ適用されます。既存の鍵を更新したい場合は、`/var/lib/https-portal`の下に保存されている既存の鍵を削除して、`https-portal`を再起動してください。

## 仕組み

以下動作を実施しています：

* [Let's Encrypt](https://letsencrypt.org)からあなたの各サブドメインのSSL証明書を取得。
* HTTPSを使用するようにNginxを設定（HTTPをHTTPSにリダイレクトしてHTTPSを強制）
* 証明書が30日以内に期限切れになる場合、毎週証明書をチェックし、更新するためのcronジョブを設定。

## Let's Encryptの利用制限について

Let's Encryptのサービスは公平な使用を保証するために利用制限が設けられています。[様々な利用制限](https://letsencrypt.org/docs/rate-limits/)について自分自身で調べてください。このドキュメントページは現在の利用制限値の公式情報源です。

ほとんどの人にとって最も重要な利用制限は：

* 時間あたり5回の検証失敗
* 週あたりの登録ドメインごとに50件の証明書
* 週あたり5件の重複証明書（更新用）

単一の証明書で複数のサブドメインにHTTPSを使用したい場合、Let's Encryptは1つの証明書に最大100のドメインを入れることをサポートしていますが、注意深い計画が必要で、自動化が難しい場合があります。そのため、HTTPS-PORTALでは単一ドメイン名の証明書のみを扱います。

HTTPS-PORTALはあなたの証明書をデータボリュームに保存し、有効な証明書が見つかった場合、期限切れの30日前まで証明書を再署名しません（環境変数`FORCE_RENEW: 'true'`を使用して証明書を強制更新することができます）。しかし、イメージを多用すると、制限に達することがあります。そのため、`STAGE`はデフォルトで`staging`に設定されており、Let's Encryptのステージングサーバーを使用しています。実験が終わり、すべてがうまくいっていると感じたら、`STAGE: 'production'`に切り替えることができます。

## トラブルシューティング

### 強制更新

証明書が正しくチェーンされていないと判断した場合は、以下の設定でコンテナをもう一度実行してください：

```yaml
https-portal:
  # ...
  environment:
    # ...
    FORCE_RENEW: 'true' # <-- here
```

これは、ACME v2がACME v1とは異なり、部分的なチェーンではなく完全なチェーンを返すためです。古い証明書が保存されている場合、HTTPS-PORTALは正しく対応できないことがあります。この問題に遭遇した場合は、`FORCE_RENEW`を実行して新しい証明書セットを取得してください。

### データボリュームをリセットする

HTTPS-PORTALが期待通りに動作していないと感じた場合は、データボリュームをリセットしてみてください：


```
docker-compose down -v
docker-compose up
```

## Credits

* [acme-tiny](https://github.com/diafygi/acme-tiny) by Daniel Roesler.
* [docker-gen](https://github.com/jwilder/docker-gen) by Jason Wilder.
* [s6-overlay](https://github.com/just-containers/s6-overlay).
