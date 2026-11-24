import { pad } from '../logic/pad'
import type { Messages } from './zh'

const WEEKDAYS = ['日', '月', '火', '水', '木', '金', '土']

export const ja: Messages = {
  htmlLang: 'ja',
  appDescription: 'うんちを記録する小さなシール手帳。データはこの端末だけに保存され、ログインも不要です。',

  date: {
    header: (d) => `${d.getMonth() + 1}月${d.getDate()}日（${WEEKDAYS[d.getDay()]}）`,
    month: (d) => `${d.getFullYear()}年${d.getMonth() + 1}月`,
    monthDay: (d) => `${d.getMonth() + 1}月${d.getDate()}日`,
    fullDate: (y, m, d) => `${y}年${m}月${d}日`,
    weekAxis: (d) => `${d.getMonth() + 1}/${d.getDate()}`,
    monthAxis: (d) => `${d.getMonth() + 1}月`,
    weekdayShort: WEEKDAYS,
    today: '今日',
    yesterday: '昨日',
    greeting: { morning: 'おはよう', noon: 'こんにちは', afternoon: 'こんにちは', evening: 'こんばんは', night: '夜ふかし中' },
    greetingLine: (greeting, header) => `${greeting}、${header}`,
    time: (d) => `${pad(d.getHours())}:${pad(d.getMinutes())}`,
  },

  units: {
    times: () => '回',
    count: (n) => `${n}回`,
    hours: () => '時間',
    days: () => '日',
    hoursValue: (n) => `${n}時間`,
    daysValue: (n) => `${n}日`,
    justNow: 'たった今',
  },

  bristol: {
    names: ['コロコロ', 'ゴツゴツ', 'ひび割れ', 'なめらか', 'ふんわり', 'どろっと', '水っぽい'],
    hints: [
      'コロコロ硬め。ちょっと便秘ぎみかも',
      '形はあるけどゴツゴツ。乾きぎみ',
      '表面に少しひび。いい感じ',
      'なめらかでやわらか。完璧！',
      'ふちがはっきりした、やわらかいかたまり',
      'どろっとして、ややゆるめ',
      '水っぽい。水分補給を忘れずに',
    ],
    groups: { dry: '硬め', ideal: '理想', soft: 'やわらかめ', loose: 'ゆるめ' },
    label: (type, name) => `タイプ${type}・${name}`,
    spoken: (type, name) => `タイプ${type} ${name}`,
    hint: (group, hint) => `${group}・${hint}`,
    pickerLabel: 'ブリストルスケール',
    unsureLabel: '形がわからない',
    unsure: 'わからない',
    skip: 'スキップ',
  },

  mood: {
    noData: 'はじめて？下の大きなシールをタップすれば記録できます',
    today: 'おなかの相棒がハートを送ってるよ',
    yesterday: '今日もお水をしっかり飲もう',
    aWhile: '野菜や果物を食べて、少し歩いてみよう',
    tooLong: 'お水と食物繊維をしっかりとってね。つらい日が続くならお医者さんへ',
  },
  moodTitle: {
    noData: 'まだ記録がありません',
    today: '今日は順調',
    yesterday: '昨日は出たよ',
    days: (n) => `${n}日出ていません`,
  },

  app: {
    dbErrorTitle: 'ローカルデータベースを開けません',
    dbErrorBody:
      'ブラウザがプライベートモードか、サイトの保存を禁止している可能性があります。PooPal の記録には IndexedDB が必要です。',
    logged: (time) => `記録しました · ${time}`,
    addDetails: '詳しく書く',
    undo: '取り消す',
    mainNav: 'メインナビゲーション',
    tabToday: '今日',
    tabStickers: 'シール帳',
    tabSettings: '設定',
  },

  home: {
    settings: '設定',
    todaySection: '今日',
    todayCount: () => ['今日 ', ' 回'],
    justVisited: 'さっき出たばかり',
    sinceLast: (elapsed) => `前回から ${elapsed}`,
    addPast: '記録し忘れた？あとから追加',
    recent: '最近の記録',
    logLabel: (n) => `記録する。今の時刻で記録します。今日は ${n} 回記録済み`,
    logTitle: '記録する',
    logFirst: '行ってきた？タップで記録',
    logNth: (n) => `今日 ${n} 枚目のシール、タップで記録`,
    thisWeek: '今週',
    dayLabel: (day, n) => `${day}、${n}回`,
    summary: '最近のようす',
    last7Days: '直近 7 日間',
    howOften: 'だいたいの間隔',
  },

  stats: {
    commonType: 'よくある形',
    averageInterval: '平均の間隔',
    perDayAll: '1日あたり · 全期間',
    perDay30: '1日あたり · 直近 30 日',
    last7: '直近 7 日',
    last30: '直近 30 日',
    total: '記録の合計',
  },

  entry: {
    edit: 'この記録を編集',
    addDetailsHint: 'タップして形やメモを追加',
    titleEdit: '編集',
    titleAdd: 'あとから追加',
    cancel: 'キャンセル',
    save: '保存',
    saveNew: '記録する',
    time: '時刻',
    date: '日付',
    clock: '時刻',
    hourAgo: '1時間前',
    thisMorning: '今朝 8時',
    lastNight: '昨夜 10時',
    shapeHeader: 'どんな形？ · ブリストルスケール',
    noteHeader: 'ひとことメモ',
    notePlaceholder: '例：昨夜は火鍋を食べて、ちょっとおなかが痛い',
    delete: 'この記録を削除',
    deleteMessage: '削除すると元に戻せません',
    deleteConfirm: '削除',
  },

  history: {
    calendar: 'カレンダー',
    list: 'リスト',
    trends: '傾向',
    viewMode: '表示方法',
    add: 'あとから追加',
    title: 'わたしのシール帳',
    emptyTitle: 'まだシールがありません',
    emptyBody: 'ホームの「記録する」をタップするか、右上の＋から以前の分を追加しましょう。',
    groupHeader: (day, n) => `${day} · ${n}回`,
    more: 'もっと前を見る',
    footnote: '記録をタップすると編集・削除できます。',
    emptyDay: 'この日はシールなし',
    monthTotal: (n) => `合計 ${n}回`,
    prevMonth: '前の月',
    nextMonth: '次の月',
    legendLess: '少',
    legendMore: '多',
  },

  trends: {
    week: '週ごと',
    month: '月ごと',
    period: '期間',
    howMany: '回数',
    sentence: (period, previous) =>
      period === 'week' ? ['今週 ', ` 回、先週 ${previous}回`] : ['今月 ', ` 回、先月 ${previous}回`],
    average: (period, average) =>
      period === 'week'
        ? `直近 12 週の平均は週 ${average}回（点線）`
        : `直近 12 か月の平均は月 ${average}回（点線）`,
    shapes: '直近 30 日の形',
    typed: (n) => `形の記録 ${n}回`,
    shapesEmpty: '記録するときに形を選ぶと、ここにグラフが表示されます。',
    shapesFootnote: 'タイプ3〜4が理想。1〜2は硬め、6〜7はゆるめです。',
    allNumbers: 'すべての数字',
    chartLabel: (period, description) =>
      `直近 12 ${period === 'week' ? '週' : 'か月'}の回数の棒グラフ：${description}`,
    chartItem: (date, n) => `${date} ${n}回`,
    listSeparator: '、',
  },

  settings: {
    title: '設定',
    done: '完了',
    looks: '見た目',
    appearance: '外観',
    appearanceOptions: { system: 'システム', light: 'ライト', dark: 'ダーク' },
    language: '言語',
    followSystem: 'システム',
    remindersHeader: 'リマインダー',
    inactivityFooter: (days, hour) => `${days}日以上出ていないときは、午前 ${hour}時にそっとお知らせします。`,
    webLimit:
      'Web 版は PooPal を開いているか、バックグラウンドに移った直後しか通知できません。完全に閉じている場合は、次に開いたときにお知らせします。',
    inactivity: 'しばらく出ていないときに通知',
    inactivityDays: '何日空いたら通知',
    daily: '毎日記録をリマインド',
    dailyTime: '通知の時刻',
    allowNotifications: 'PooPal の通知を許可する',
    notificationsDenied: '通知がオフになっています。ブラウザまたはシステムの設定で PooPal の通知を許可してください。',
    notificationsUnsupported: 'このブラウザは Web 通知に対応していません。',
    notificationsIos:
      'iPhone では、Safari で「共有 › ホーム画面に追加」をしてから、ホーム画面から開くとリマインダーをオンにできます（iOS 16.4 以降）。',
    decrease: '減らす',
    increase: '増やす',
  },

  backup: {
    header: 'バックアップ',
    passwordTooShort: 'パスワードは 4 文字以上にしてください',
    passwordMismatch: 'パスワードが一致しません',
    exportFailed: (message) => `書き出しに失敗しました：${message}`,
    importDone: (summary) => `読み込み完了：${summary}`,
    importFailed: (message) => `読み込みに失敗しました：${message}`,
    readFailed: (message) => `ファイルを読み取れませんでした：${message}`,
    footerEncrypted: '暗号化したバックアップはパスワードがないと読み込めません。忘れると復元できません。',
    footerPlain:
      'JSON ファイルとして書き出し、「ファイル」に保存したり自分に送ったりできます。読み込むと今の記録に統合され、重複は自動でスキップされます。iOS 版 PooPal のバックアップとも互換性があります。',
    usePassword: 'バックアップにパスワードをかける',
    newPassword: 'パスワード（4 文字以上）',
    repeatPassword: 'もう一度入力',
    preparing: '準備中…',
    export: 'バックアップを書き出す',
    ready: 'バックアップの準備ができました。ここをタップして保存',
    import: 'バックアップを読み込む',
    passwordTitle: 'このバックアップにはパスワードがあります',
    cancel: 'キャンセル',
    importAction: '読み込む',
    passwordPrompt: '書き出し時に設定したパスワードを入力してください。',
    passwordLabel: 'バックアップのパスワード',
    ok: 'OK',
    fileWord: 'バックアップ',
    encryptedWord: '暗号化',
    summary: (inserts, fills, duplicates) => {
      const parts = [`${inserts}件を追加`]
      if (fills > 0) parts.push(`${fills}件に形やメモを補完`)
      parts.push(`重複 ${duplicates}件をスキップ`)
      return parts.join('、')
    },
    errors: {
      invalidFile: 'PooPal のバックアップファイルではないか、ファイルが壊れています',
      passwordRequired: 'このバックアップにはパスワードがあります。入力してください',
      wrongPassword: 'パスワードが違います。もう一度どうぞ',
      unsupportedVersion: (version) => `バックアップのバージョン ${version} は新しすぎます。先に PooPal を更新してください`,
      cryptoUnavailable:
        'このブラウザでは暗号化を使えません（HTTPS が必要です）。HTTPS のアドレスで PooPal を開いてください',
    },
  },

  about: {
    privacy:
      '記録はこのブラウザの中だけに保存されます。ログイン不要で、ほかの人には見えません。機種変更やブラウザの変更、サイトデータの削除の前に、バックアップを書き出しておきましょう。',
    install: 'iPhone の Safari で「共有 › ホーム画面に追加」をタップすると、アプリのように使えてオフラインでも開けます。',
    demo: 'いまはサンプルデータを表示中です。変更はあなたの記録には保存されません。',
  },

  reminders: {
    inactivityTitle: (days) => `${days}日間うんちの記録がありません`,
    inactivityBody: 'お水や野菜・果物をとってね。出たら PooPal で記録しよう',
    dailyTitle: '今日はうんち出た？',
    dailyBody: 'PooPal をタップして、今日のおなか日記をつけよう',
  },

  demoNotes: { 1: '昨夜は火鍋', 6: '朝に大きなカップでコーヒー', 13: 'ちょっとおなかの調子が悪い', 30: '旅行1日目' },
}
