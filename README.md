## これは何？

F# で作成したクライアント アプリケーションに対し、WiX を使用して Windows インストーラー パッケージ（msi ファイル）を作成、デプロイ（配布）するサンプル。

「Hello, F#!」するだけの簡単なコンソール アプリケーションを、FSharp.Core.dll を含めてデプローイするためにパッケージングする。［プラットフォーム ターゲット］は x86 とする。

とりあえず Visual Studio でソリューション開いてビルドすれば msi が得られる。残念ながら、Express を使っている人は Wix のプロジェクトが開けない、Visual Studio でビルドできないと思われるので、バッチ ファイルをあわせて用意した。HelloFSharp プロジェクトを Release ビルドした後で、HelloFSharpSetup\build.bat を実行していただきたい。あるいは、［ビルド後イベントのコマンド ライン］を使用してもよいだろう。

で、あと、WiX 基礎文法最速マスター的な何か。

## WiX Toolset

WiX Toolset とは Windows Installer XML Toolset の略称。WiX はウィックスと読む。XML から Windows インストーラー パッケージを作成するためのツールセットであり、Microsoft 初のオープンソース ソフトウェアとしても知られる。

[WiX Toolset](http://wixtoolset.org/)

XML ベースの wxs ファイルを記述し、candle および light コマンドを通じて msi ファイルを生成する。candle と light は、それぞれコンパイラとリンカに相当する。wxs ファイルを candle コマンドで wixobj ファイルに変換し、さらに wixobj ファイルを light コマンドで msi ファイルに変換する。

製品版の Visual Studio がインストールされていれば、プロジェクト テンプレートに［Windows Installer XML］の項目が追加される。［Setup Project］を選んでソリューションにプロジェクトを追加。インテリセンスのサポートを受けながら、Product.wxs を編集すればよい。Express 勢は手書きでがんばれ。

なお、Setup Project は、デプロイ対象のプロジェクトの後にビルドされる必要があるため、ソリューションのコンテキスト メニューから［プロジェクト依存関係...］を適切に設定しておくこと。当たり前ではあるが、忘れても気づきづらく、うっかりすると、一つ前のビルドがパッケージングされてしまうので注意されたい。

## wxs ファイルの構造

wxs ファイルの構造は、大まかな以下のようになる。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product>
    :
    :
  </Product>
</Wix>
```

`Wix` タグと `Product` タグで全体を囲う恰好だ。そして、`Product` タグの中に、任意のタグとそれらの属性を記述していくことでインストーラー パッケージの定義を行うのであるが、`Product` タグの中にすべての定義を詰め込むと、見通しが悪くなってしまう。これを解決するために `Fragment` タグがある。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product>
    :
    :
  </Product>

  <Fragment>...</Fragment>

  <Fragment>...</Fragment>

  <Fragment>...</Fragment>
</Wix>
```

`Fragment` タグを使えば、定義を分割して記述することが可能になる。各 `Fragment`タグは、複数の wxs ファイルに分割することもできるので、大規模で複雑なプロジェクトではより効果的だ。

では `Fragment` を使って実際に書いてみる。`Fragment` タグの中に `Feature` というタグを置きたい。しかしながら、困ったことに、`Feature` タグは `Product` タグの要素として定義する必要がある。

```xml
<Product>
  <Feature Id="ProductFeature">
    :
    :
  </Feature>
</Product>
```

そんなときは参照タグを利用する。`Feature` タグには、それを参照するための `FeatureRef` タグがある。`Fragment` に `Feature` を定義しておき、`Product` からは `FeatureRef` で参照すればよいのである。

```xml
<Product>
  <FeatureRef Id="ProductFeature" />
</Product>

<Fragment>
  <Feature Id="ProductFeature">
    :
    :
  </Feature>
</Fragment>
```

参照関係の紐付けは、`Id` 属性によって明示する。このような参照用のタグは、参照先のタグに応じた専用のタグとして用意され、たとえばこれ以外にも、`Directory` タグを参照する `DirectoryRef` タグや、`Component` タグを参照する `ComponentRef` タグなどがある。

## GUID

Windows インストーラーは、同製品の同バージョンを重複してインストールしないよう検出する。また、同じ製品の上位バージョンはバージョンアップ インストールをする。このような機能の実現のためには、グローバルに一意な識別である GUID が必要となる。製品のための情報を定義する `Product` タグにおいて、`Id` 属性と `UpgradeCode` 属性に GUID を設定する。

```xml
<Product Id="*" Language="1041" Codepage="932"
         Name="Hello F#" Version="1.0.0.0" Manufacturer="OreOre Corp."
         UpgradeCode="70b58464-5acc-49ab-90fa-fdf0a224a357">
  :
  :
</Product>
```

`Id` 属性は、当該製品の当該バージョンを一意に識別するための GUID である。ここでは `*` を指定したが、そうすると、ビルドごとに GUID が自動生成される。`UpgradeCode` タグは、当該製品を一意に識別するための GUID であり、一度付けた GUID をずっと使い続ける必要がある。すなわち、`UpgradeCode` が同じで `Id` が異なる場合に、Windows インストーラーはそれをバージョンアップだと判断する。

GUID は世界中で一意でなければならない。そのため、自分の製品のためには自分で GUID を生成する必要がある。`Id` には `*` による自動生成が使えるし、`UpgradeCode` に関しては VS テンプレートによって自動で差し込まれる。明示的に指定したい場合は VS のメニューから［GUID の作成］が使用できる。決して、どこかの誰かのコードを丸ごとコピペして GUID を衝突させたりしないこと。絶対に。

## Windwos インストーラーでの考え方

インストーラー パッケージにどのファイルを含めるか、そしてそれらはインストールしたときにどこに配置されるか。これの定義には、インストール時のフォルダ構成を示すようにして、`Directory` タグの入れ子を記述する。

```xml
<Directory Id="TARGETDIR" Name="SourceDir" />
  <Directory Id="ProgramFilesFolder">
    <Directory Id="INSTALLFOLDER" Name="Hello FSharp">
      :
      :
    </Directory>
  </Directory>
</Directory>
```

それぞれの `Id` 属性を見よう。`TARGETDIR` は決め打ちのルート要素で、`ProgramFilesFolder` は _Program Files_ ディレクトリーに対応する。`INSTALLFOLDER` が、配布対象のアプリケーションのためのフォルダで、`Name` 属性によってディレクトリー名を指定する。よって上記の定義では、通常 "C:\Program Files\Hello FSharp" ディレクトリーにインストールが行われることになる。

気を付けておきたいのは、`ProgramFilesFolder` が示す _Program Files_ は x86 用ディレクトリーであるということだ。つまり 64bit OS において、`ProgramFilesFolder` は `%ProgramFiles(x86)%` を示すのである。x64 環境での `%ProgramFiles%` を指定するには `ProgramFiles64Folder` を使用すること。また加えて、x64 向けのパッケージングには、candle コマンドに -arch x64 オプションの指定が必要となる。

なお、`ProgramFilesFolder` や `ProgramFiles64Folder` のような予約された `Id` の一覧については、[こちらのページ](http://msdn.microsoft.com/en-us/library/aa370905.aspx#system_folder_properties)を参照してほしい。

さて、Hello FSharp ディレクトリーの中身だ。インストールされるファイルは、それぞれ `Component` タグで括った `File` タグによって列挙する。

```xml
<Component Id="HelloFSharp.exe" Guid="*">
  <File Id="HelloFSharp.exe" Name="HelloFSharp.exe"
        Source="..\HelloFSharp\bin\Release\HelloFSharp.exe" KeyPath="yes" />
</Component>
<Component Id="HelloFSharp.exe.config" Guid="*">
  <File Id="HelloFSharp.exe.config" Name="HelloFSharp.exe.config"
        Source="..\HelloFSharp\bin\Release\HelloFSharp.exe.config" KeyPath="yes" />
</Component>
```

`Component` はインストールの単位であり、インストールする複数のリソースを取りまとめるものである。さしあたりそのリソースとは `File` であるが、1つの `Component` ごとに1つの `File` を含めることが推奨されている。なぜなら、Windows インストーラーは、スモール アップデートと呼ぶ一部のファイルだけを入れ替えるインストール、いわゆるパッチ適用の機能をサポートするのだが、そのためには、ファイルの一つひとつが入れ替え可能なインストールの単位となっているべきだからである。

`File` タグは、`Source` 属性で配布対象のファイル パス（つまり、開発環境でのパス）を指定し、`Name` 属性でインストール先でのファイル名を指定する。`Id` 属性は一意な識別子であるが、通常は `Name` 属性と揃えておけばよい。別フォルダに同名ファイルがあるような場合は、重複を避けるために適当なサフィックスを付けるなどして対応すること。`KeyPath` 属性には、1つの `Component` ごとに1つの `File` を含めるというベスト プラクティスを守っている場合、必ず `yes` を設定する。`KeyPath` 属性が `yes` のタグは、その `Component` が正しくインストールされているかどうかの判断のために用いるものであることを意味する。

`Component` タグは、`Id` および `Guid` 属性を持つ。`Id` 属性は、`ComponentRef` で参照するために使う一意な識別子である。ここでは `File` の `Id` と同じでよい。対して `Guid` は、パッチ適用時にそれを一意に識別するための GUID である。`Component` タグの `Guid` 属性には、`*` を指定すると GUID を自動生成することができて、これは KeyPath 要素のインストール先ディレクトリとファイル名に基づいて決定される。KeyPath 要素はここでは `File` だ。よって、`Component` が含む `File` を変更しない限り、同じ GUID が付番される。

こうして定義された `Directory` 構造は、インストーラー パッケージにどのファイルをどんな構造で含めるかを定義したものに過ぎない。それらの内、どれを実際にインストール先に展開するかは、別途、`Feature` タグによって定義する必要がある。

```xml
<Feature Id="ProductFeature" Title="Product Feature" Level="1">
  <ComponentRef Id="HelloFSharp.exe" />
  <ComponentRef Id="HelloFSharp.exe.config" />
  <ComponentRef Id="HelloFSharp.XML" />
</Feature>
```

一見すると、`Directory` と `Feature` は無駄な重複定義のようにも思える。しかし、おそらくはあなたにも、標準インストール、完全インストール、カスタム インストールのどれにするかインストール ウィザードに聞かれた経験があるだろう。これはつまり、そのために必要なしくみである。

## スタート画面（スタート メニュー）へのショートカットの登録

インストール時にほぼ必須の機能として欲しいものに、スタート画面（スタート メニュー）へのショートカットの登録が挙げられるだろう。これには、予約された `Id` である `ProgramMenuFolder` を使用して、その `Directory` 構造を定義する。

```xml
<Directory Id="ProgramMenuFolder">
  <Directory Id="HelloFSharpProgramsFolder" Name="Hello F#">
    <Component Id="HelloFSharpShortcut" Guid="*">
      <Shortcut Id="HelloFSharpStartMenuShortcut" Name="Hello F#"
                Description="Hello F# はこんにちはするプログラムです。"
                Target="[INSTALLFOLDER]HelloFSharp.exe" WorkingDirectory="INSTALLFOLDER"/>
      <RemoveFolder Id="HelloFSharpProgramsFolder" On="uninstall"/>
      <RegistryValue Root="HKCU" Key="Software\OreOre\HelloFSharp"
                     Name="installed" Type="integer" Value="1" KeyPath="yes"/>
    </Component>
  </Directory>
</Directory>
```

`Component` には3つのタグが含まれる。`Shortcut` タグはショートカットそれそのものであるが、他の2つは何か。`RemoveFolder` タグは、文字通りフォルダーの削除を行う。`On` 属性でアンインストール時に、`Id` 属性で "Hello F#" フォルダーを、削除することを指定している。自身のショートカットのために作ったフォルダーを、自身のアンインストール時に行儀よく消す、という定義である。`RegistryValue` タグはレジストリーに値を登録する。ここで重要なのは `KeyPath` 属性だ。ショートカットのためのこの `Component` が正しくインストールされているかどうか、その判断のためにレジストリーを使用しているのである。

`Shortcut` タグの `Target` 属性にあらわれる [...] なる記法についても解説しておこう。`Directory` の `Id` を [...] で括って示すことで、その `Id` のパスを展開することができる。すなわち、"[INSTALLFOLDER]HelloFSharp.exe" は "C:\Program Files\Hello FSharp\HelloFSharp.exe" のように展開される。一方で、`WorkingDirectory` 属性には `Directory` の `Id` を指定することになっているため、[...] で括らずともパスが解決される。
