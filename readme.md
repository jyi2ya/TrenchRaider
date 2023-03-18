# 要写一个什么东西

写什么来着

# TODO

* [ ] rfc 6749

## Stage 1

* [X] 用户注册
* [X] 用户登录
* [X] 用户修改信息
* [X] 邮件验证
* [X] 限制邮件频率
* [X] 错误处理
* [ ] 把呃呃数据库换成真的数据库

## Stage 2

* [X] 实现一个 Authorization Code 模式的 OAuth 2.0 服务
* [X] 自动化测试
* [X] 错误处理
* [X] 替换现在非常 ad-hoc 的 token 和 id 生成代码
* [X] 令牌过期
* [ ] 限制请求资源范围

## Stage 3

* [X] 实现 Refresh Token 流程
* [ ] 实现符合规范的 OAuth2.0

## Stage 4

* [X] 不知道是啥反正和 OIDC 有关
* [X] `/userinfo` endpoint
* [X] 提供更换 ~~加密方式~~ 以及密钥的方法

## Stage 5

* [ ] 参考 bangumi 提供番剧收藏功能
* [ ] 对番剧评分、吐槽
* [ ] 查看、搜索收藏
* [ ] 好友功能

## Stage 6

* [ ] 提供绑定 bangumi 的 api
* [ ] 同步数据

怎么这么多

糟了，写不完了！怎么办

# api

```
/debug/kill/:uid                   ....  GET   没实现
/user/query/:uid                   ....  GET   没实现
/steal_data_from_bangumi           ....  GET   没实现
/callback/:type/:id                ....  POST  没实现

/login                             ....  GET   用户在这里填表然后登录
/register                          ....  GET   用户在这里填表然后注册

/auth/authorize                    ....  GET   OIDC/OAuth2 验证中，由 client 重定向到此
/auth/confirm_authorize            ....  GET   用户在此处确认对 client 的授权
/auth/token                        ....  POST  完成 token 的颁发和刷新
/auth/userinfo                     ....  GET   仅限 OIDC，由 access_token 获取用户信息
/.well-known/openid-configuration  ....  GET   别的程序读这个文件就能知道怎么用我的身份验证服务

/client/new                        ....  POST  注册 client 的接口

/user/login                        ....  POST  用户登录接口
/user/verify_email                 ....  GET   用户验证邮件接口
/user/resend_email                 ....  GET   用户发现自己没收到邮件然后点这个就能重新发一封
/user/new                          ....  POST  用户注册接口
/user/upload_avantar               ....  POST  没实现
/user/drop                         ....  POST  用户删除接口
/user/replace                      ....  PUT   用户全量更新接口
/user/update                       ....  PATCH 用户差量更新接口

/lwiw                              ....  GET   跳转到林中小女巫的 steam 商店页面
```
