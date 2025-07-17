---
layout: post
title: 💎【Ruby】Ruby和gem概念知识简介
date: 2025-7-17
---
## Ruby
Ruby是一个编程语言，意思是红宝石。
后缀是 `.rb` 

## rake
rake 是 Ruby 语言的类 make 程序 ，有 `Makefile` 所以也有 `RakeFile` 。可以定义任务、源码依赖。

## gem
gem 是 Ruby 的包管理器，命令就是 `gem`， 包后缀名字也是 `.gem`， 类似于 `rpm`。

但是 `rpm `只能安装本地包，不能联网下载。联网下载要用 `yum`。

就像 Debian 系里的包管理器是 `dpkg`， 不能联网下载，联网下载用 `apt`。

## gemspec
gemspec 是 `gem` 的描述文件。
类似于 `dpkg` 打包需要spec文件。

> 注意gem对应文件是gemspec。 Gemfile 实际上和 gem无关，它是bundler的配置文件名


## GemFile
GemFile描述了相关的Ruby应用需要的gem依赖等信息。

> gem存在的问题是没有对依赖的版本控制。大多数gem都被安装到同一个路径下，如果存在多个需要gem的项目，如何对依赖的gem版本进行管理，是一个问题。

## bundler
bundler 是Ruby程序的依赖管理工具。 它也是一个gem，但是它用于管理版本错综复杂的gem们。

Bundler的出现修复了RubyGems没有解决的问题。Ruby 的开发者只需要列出他所需要的 Gem，然后 Bundler 就会找出合适的版本让它们在一起工作，并且把一个可行解（但不一定是最优解）放入 Gemfile.lock。这个文件保证了共享代码或者部署到服务器时能够安装到正确的依赖版本。

执行`bundler install`时，`bundler`会读取`Gemfile`文件并一次性安装所有依赖gem。

Bundler负责下载Gemfile中所有的gem。
在应用根目录 `Gemfile` 文件里声明依赖后，Bundler 会去 source 指定的 `https://rubygems.org` 上寻找 gem。

Bundler和GemFile并不是必须的，但推荐使用。因为Bundler可以保证在不同平台上安装对应的依赖Gem版本。

所有的Jekyll命令都可以加上`bundler exec`前缀 。

## bundle
bundle 是另外一个gem， 用来解决把 “bundler 错误拼写成 bundle” 的问题。唯一作用就是按照bundler。让二者同义但不报错。
