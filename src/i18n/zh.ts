import { pad } from '../logic/pad'

const WEEKDAYS = ['日', '一', '二', '三', '四', '五', '六']

/** A unit that doesn't change with the count, typed so other languages can pluralize it. */
const fixed =
  <T>(value: T): ((n: number) => T) =>
  () =>
    value

/** Simplified Chinese, the source language. Every other locale must have this exact shape. */
export const zh = {
  htmlLang: 'zh-CN',
  appDescription: '记录便便的小贴纸手帐。数据只存在这台设备上，不用登录。',

  date: {
    /** "11月2日 星期一" */
    header: (d: Date) => `${d.getMonth() + 1}月${d.getDate()}日 星期${WEEKDAYS[d.getDay()]}`,
    /** "2026年11月" */
    month: (d: Date) => `${d.getFullYear()}年${d.getMonth() + 1}月`,
    /** "11月2日" */
    monthDay: (d: Date) => `${d.getMonth() + 1}月${d.getDate()}日`,
    /** "2026年11月17日" */
    fullDate: (y: number, m: number, d: number) => `${y}年${m}月${d}日`,
    /** Bar chart axis: "11/2" for weeks, "11月" for months. */
    weekAxis: (d: Date) => `${d.getMonth() + 1}/${d.getDate()}`,
    monthAxis: (d: Date) => `${d.getMonth() + 1}月`,
    /** Indexed by `Date.getDay()` (0 = Sunday). */
    weekdayShort: WEEKDAYS,
    today: '今天',
    yesterday: '昨天',
    greeting: { morning: '早上好', noon: '中午好', afternoon: '下午好', evening: '晚上好', night: '夜深了' },
    greetingLine: (greeting: string, header: string) => `${greeting}，${header}`,
    time: (d: Date) => `${pad(d.getHours())}:${pad(d.getMinutes())}`,
  },

  units: {
    /** Unit after a count of visits: "3 次". */
    times: fixed('次'),
    count: (n: number) => `${n} 次`,
    hours: fixed('小时'),
    days: fixed('天'),
    hoursValue: (n: number) => `${n} 小时`,
    daysValue: (n: number) => `${n} 天`,
    justNow: '刚刚',
  },

  bristol: {
    names: ['硬球球', '疙瘩条', '裂纹条', '光滑条', '软团团', '糊糊状', '水水状'],
    hints: [
      '一颗颗硬硬的，可能有点便秘了',
      '成条但疙疙瘩瘩，偏干',
      '成条有点裂纹，挺好的',
      '光滑柔软，完美！',
      '软软的小团，边缘清楚',
      '糊糊的，有点稀',
      '水水的，记得多补水哦',
    ],
    groups: { dry: '偏干', ideal: '理想', soft: '偏软', loose: '偏稀' },
    /** "4 型 · 光滑条" */
    label: (type: number, name: string) => `${type} 型 · ${name}`,
    /** Accessible name: "4 型 光滑条" */
    spoken: (type: number, name: string) => `${type} 型 ${name}`,
    hint: (group: string, hint: string) => `${group} · ${hint}`,
    pickerLabel: '布里斯托分类',
    unsureLabel: '不确定形态',
    unsure: '不确定',
    skip: '先跳过',
  },

  mood: {
    noData: '第一次？点下面的大贴纸就记好啦',
    today: '肠道小伙伴给你比个心',
    yesterday: '今天也记得多喝水呀',
    aWhile: '吃点蔬果，起来走走吧',
    tooLong: '多喝水、多吃点膳食纤维；一直不舒服记得看医生哦',
  },
  moodTitle: {
    noData: '还没有记录哦',
    today: '今天顺顺利利',
    yesterday: '昨天来过啦',
    days: (n: number) => `已经 ${n} 天没来了`,
  },

  app: {
    dbErrorTitle: '打不开本地数据库',
    dbErrorBody: '浏览器可能处于无痕模式，或禁止了网站存储。PooPal 需要 IndexedDB 才能保存记录。',
    logged: (time: string) => `记好啦 · ${time}`,
    addDetails: '加点细节',
    undo: '撤销',
    mainNav: '主导航',
    tabToday: '今天',
    tabStickers: '贴纸本',
    tabSettings: '设置',
  },

  home: {
    settings: '设置',
    todaySection: '今天',
    /** Text before and after today's count, which is set large between them. */
    todayCount: fixed<[string, string]>(['今天 ', ' 次']),
    justVisited: '刚刚来过',
    sinceLast: (elapsed: string) => `距上次 ${elapsed}`,
    addPast: '忘了记？补一条',
    recent: '最近几次',
    logLabel: (n: number) => `记一下，记录现在。今天已记录 ${n} 次`,
    logTitle: '记一下',
    logFirst: '刚去过？点我就记好',
    logNth: (n: number) => `今天的第 ${n} 张贴纸，点我就记好`,
    thisWeek: '这一周',
    dayLabel: (day: string, n: number) => `${day}，${n} 次`,
    summary: '最近怎么样',
    last7Days: '近 7 天来了',
    howOften: '大概多久一次',
  },

  stats: {
    commonType: '最常见的样子',
    averageInterval: '平均多久一次',
    perDayAll: '平均每天 · 全部',
    perDay30: '平均每天 · 近 30 天',
    last7: '近 7 天',
    last30: '近 30 天',
    total: '一共记了',
  },

  entry: {
    edit: '编辑这条记录',
    addDetailsHint: '点一下，补上形态和小备注',
    titleEdit: '改一改',
    titleAdd: '补一条',
    cancel: '取消',
    save: '保存',
    saveNew: '记好了',
    time: '时间',
    date: '日期',
    clock: '几点',
    hourAgo: '1 小时前',
    thisMorning: '今早 8 点',
    lastNight: '昨晚 10 点',
    shapeHeader: '长什么样？· 布里斯托分类',
    noteHeader: '想说点什么',
    notePlaceholder: '比如：昨晚吃了火锅，有点肚子痛',
    delete: '删掉这一条',
    deleteMessage: '删掉就找不回来了哦',
    deleteConfirm: '删除',
  },

  history: {
    calendar: '日历',
    list: '列表',
    trends: '趋势',
    viewMode: '显示方式',
    add: '补一条',
    title: '我的贴纸本',
    emptyTitle: '还没有贴纸呢',
    emptyBody: '去首页点一下「记一下」，或者点右上角补一条之前的。',
    groupHeader: (day: string, n: number) => `${day} · ${n} 次`,
    more: '看看更早的',
    footnote: '点一条可以改，也可以在里面删掉。',
    emptyDay: '这天没有贴纸',
    monthTotal: (n: number) => `共 ${n} 次`,
    prevMonth: '上个月',
    nextMonth: '下个月',
    legendLess: '少',
    legendMore: '多',
  },

  trends: {
    week: '按周',
    month: '按月',
    period: '周期',
    howMany: '来了几次',
    /** Text around this period's count, which is set bold between them. */
    sentence: (period: 'week' | 'month', previous: number): [string, string] => {
      const unit = period === 'week' ? '周' : '月'
      return [`这${unit} `, ` 次，上${unit} ${previous} 次`]
    },
    average: (period: 'week' | 'month', average: string) => {
      const unit = period === 'week' ? '周' : '月'
      return `最近 12 ${unit}平均每${unit} ${average} 次（虚线）`
    },
    shapes: '近 30 天长什么样',
    typed: (n: number) => `${n} 次有记录`,
    shapesEmpty: '记的时候顺手选一下形态，这里就会画出来。',
    shapesFootnote: '3–4 型最理想；1–2 型偏干，6–7 型偏稀。',
    allNumbers: '全部数字',
    chartLabel: (period: 'week' | 'month', description: string) =>
      `最近 12 ${period === 'week' ? '周' : '月'}的次数柱状图：${description}`,
    chartItem: (date: string, n: number) => `${date} ${n} 次`,
    listSeparator: '，',
  },

  settings: {
    title: '设置',
    done: '完成',
    looks: '看起来',
    appearance: '外观',
    appearanceOptions: { system: '跟随系统', light: '浅色', dark: '深色' },
    language: '语言',
    followSystem: '跟随系统',
    remindersHeader: '小提醒',
    inactivityFooter: (days: number, hour: number) => `超过 ${days} 天没来的话，上午 ${hour} 点轻轻提醒你。`,
    webLimit: '网页版只能在 PooPal 开着或刚切到后台时发提醒；完全关掉后，会在下次打开时补上。',
    inactivity: '太久没来时提醒我',
    inactivityDays: '超过几天算太久',
    daily: '每天提醒我记一下',
    dailyTime: '提醒时间',
    allowNotifications: '允许 PooPal 发通知',
    notificationsDenied: '通知权限已关闭。请在浏览器或系统设置里允许 PooPal 发通知。',
    notificationsUnsupported: '这个浏览器不支持网页通知。',
    notificationsIos: 'iPhone 上要先在 Safari 点「分享 › 添加到主屏幕」，从主屏幕打开后才能开启提醒（需要 iOS 16.4 及以上）。',
    decrease: '减少',
    increase: '增加',
  },

  backup: {
    header: '备份',
    passwordTooShort: '密码至少 4 位',
    passwordMismatch: '两次输入的密码不一致',
    exportFailed: (message: string) => `导出失败：${message}`,
    importDone: (summary: string) => `导入完成：${summary}`,
    importFailed: (message: string) => `导入失败：${message}`,
    readFailed: (message: string) => `读取文件失败：${message}`,
    footerEncrypted: '加密后只有输入密码才能导入，密码忘记将无法恢复。',
    footerPlain: '导出为 JSON 文件，可以存到「文件」或发给自己。导入会合并到现有记录，重复的自动跳过。',
    usePassword: '给备份加个密码',
    newPassword: '设置密码（至少 4 位）',
    repeatPassword: '再输入一次',
    preparing: '正在准备…',
    export: '导出备份',
    ready: '备份准备好了，点这里保存',
    import: '导入备份',
    passwordTitle: '这个备份设置了密码',
    cancel: '取消',
    importAction: '导入',
    passwordPrompt: '请输入导出时设置的密码。',
    passwordLabel: '备份密码',
    ok: '好',
    fileWord: '备份',
    encryptedWord: '加密',
    summary: (inserts: number, fills: number, duplicates: number) => {
      const parts = [`新增 ${inserts} 条`]
      if (fills > 0) parts.push(`补充 ${fills} 条的形态或备注`)
      parts.push(`跳过 ${duplicates} 条重复`)
      return parts.join('，')
    },
    errors: {
      invalidFile: '这不是 PooPal 的备份文件，或者文件已损坏',
      passwordRequired: '这个备份设置了密码，请输入密码',
      wrongPassword: '密码不对，再试一次吧',
      unsupportedVersion: (version?: number) => `备份版本 ${version} 太新了，请先更新 PooPal`,
      cryptoUnavailable: '当前浏览器不支持加密（需要 HTTPS 访问），请换用 HTTPS 地址打开 PooPal',
    },
  },

  about: {
    privacy: '你的记录只存在这个浏览器里，不用登录，谁也看不到。换手机、换浏览器或清理网站数据前，记得先导出备份哦。',
    install: '在 iPhone 的 Safari 里点「分享 › 添加到主屏幕」，用起来就像 App 一样，没网也能打开。',
    demo: '现在看的是示例数据，改动不会保存到你的记录里。',
  },

  reminders: {
    inactivityTitle: (days: number) => `已经 ${days} 天没有便便记录啦`,
    inactivityBody: '多喝水、吃点蔬菜水果，便便了记得来 PooPal 记一笔哦',
    dailyTitle: '今天便便了吗？',
    dailyBody: '来 PooPal 点一下，记录今天的肠道小日记吧',
  },

  demoNotes: { 1: '昨晚吃了火锅', 6: '早上喝了一大杯咖啡', 13: '有点肚子不舒服', 30: '旅行第一天' } as Record<number, string>,
}

export type Messages = typeof zh
