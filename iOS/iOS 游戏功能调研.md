# iOS 游戏调研

## 目标

调研业界主流非游戏类 App 中，小游戏技术实现方案。

## 调研技术

利用 iOS 越狱设备和 UI 分析工具 Reveal，通过查看 App 内游戏界面层级，分析其实现技术。

### 业界主流 App 调研

### 京东

#### 功能入口

我的 > 游戏与互动

<img src="./images/jd_宠汪汪.png" width="50%" height="50%" />

#### 游戏技术实现

* 宠汪汪(**H5**)

  <img src="./images/jd_宠汪汪.png" width="50%" height="50%" />

* 摇钱树(**H5**)

  <img src="./images/jd_摇钱树.png" width="50%" height="50%" />

* 天天加速(**H5**)

  <img src="./images/jd_天天加速.png" width="50%" height="50%" />

* 种豆得豆(**H5**)

  <img src="./images/jd_种豆得豆.png" width="50%" height="50%" />

* 京奇世界(**RN**)

  <img src="./images/jd_京奇世界.png" width="50%" height="50%" />

## 美团

#### 功能入口

首页 > 更多 > 娱乐

<img src="./images/mt.png" width="50%" height="50%" />

#### 游戏入口

* 免费领水果(**H5**)

  <img src="./images/mt_免费领水果.png" width="50%" height="50%" />

* 袋鼠快跑(**H5**)

  <img src="./images/mt_袋鼠快跑.png" width="50%" height="50%" />

### 淘宝

#### 功能入口

我的淘宝 > 频道广场 > 互动娱乐

<img src="./images/tb.png" width="50%" height="50%" />

#### 游戏技术实现

* 天猫农场(**H5**)

  <img src="./images/tb_天猫农场2.png" width="50%" height="50%" />

  <img src="./images/tb_天猫农场.png" width="50%" height="50%" />

* 金币庄园（**H5**）

  <img src="./images/tb_金币庄园.png" width="50%" height="50%" />

### 支付宝

#### 功能入口

首页 > 更多 > 教育公益

<img src="./images/alipay.png" width="50%" height="50%" />

#### 游戏技术实现

* 蚂蚁森林（**H5**）

  <img src="./images/alipay_蚂蚁森林.png" width="50%" height="50%" />

* 蚂蚁庄园（**H5**）

  <img src="./images/alipay_蚂蚁庄园.png" width="50%" height="50%" />


### 拼多多

#### 功能入口

首页 > 多多果园/多多爱消除/多多赚大钱

<img src="./images/pdd.png" width="50%" height="50%" />

#### 游戏技术实现

* 多多果园（H5）

  <img src="./images/pdd_多多果园.png" width="50%" height="50%" />

* 多多爱消除（H5）

  <img src="./images/pdd_多多爱消除.png" width="50%" height="50%" />

* 多多赚大钱（H5）

  <img src="./images/pdd_多多赚大钱.png" width="50%" height="50%" />

### 微信

#### 功能入口

发现 > 游戏

<img src="./images/pdd_多多赚大钱.png" width="50%" height="50%" />

#### 游戏技术实现

* 欢乐斗地主(WAOpenGLView/EJJavaScriptView/EAGLView)

  <img src="./images/wx_欢乐麻将.png" width="50%" height="50%" />

* 腾讯桌球(WAOpenGLView/EJJavaScriptView/EAGLView)

  <img src="./images/wx_腾讯桌球.png" width="50%" height="50%" />

* 欢乐麻将(WAOpenGLView/EJJavaScriptView/EAGLView)

  <img src="./images/wx_欢乐斗地主.png" width="50%" height="50%" />

## 总结

App 名称 | 游戏 | 实现技术
----|----|------
京东 | 宠汪汪、摇钱树、京奇世界、天天加速、种豆得豆 | 京奇世界使用 RN 实现，其他用 H5 实现
美团 | 袋鼠快跑、免费领水果 | H5
拼多多 | 多多果园、多多爱消除、多多赚大钱 | H5
支付宝 | 蚂蚁森林、蚂蚁庄园 | H5
淘宝 | 天猫农场、金币庄园 | H5
微信 | 欢乐斗地主、腾讯桌球、欢乐麻将 | WAOpenGLView/EJJavaScriptView/EAGLView

目前业界主流 App 中的小游戏主要使用 H5 实现，微信里边一些免下载的游戏没有使用 WKWebView，而是使用 OpenGL、EJJavaScriptView 实现，具体技术需要进一步研究。