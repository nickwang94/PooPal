import { pad } from '../logic/pad'
import type { Messages } from './zh'

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const WEEKDAYS_LONG = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
const MONTHS_LONG = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
]

const plural = (n: number, one: string, many: string) => (n === 1 ? one : many)
const visits = (n: number) => `${n} ${plural(n, 'visit', 'visits')}`

export const en: Messages = {
  htmlLang: 'en',
  appDescription: 'A little sticker journal for your poops. Your data stays on this device, no sign-up needed.',

  date: {
    header: (d) => `${WEEKDAYS_LONG[d.getDay()]}, ${MONTHS[d.getMonth()]} ${d.getDate()}`,
    month: (d) => `${MONTHS_LONG[d.getMonth()]} ${d.getFullYear()}`,
    monthDay: (d) => `${MONTHS[d.getMonth()]} ${d.getDate()}`,
    fullDate: (y, m, d) => `${MONTHS[m - 1]} ${d}, ${y}`,
    weekAxis: (d) => `${d.getMonth() + 1}/${d.getDate()}`,
    monthAxis: (d) => MONTHS[d.getMonth()],
    weekdayShort: WEEKDAYS,
    today: 'Today',
    yesterday: 'Yesterday',
    greeting: {
      morning: 'Good morning',
      noon: 'Good afternoon',
      afternoon: 'Good afternoon',
      evening: 'Good evening',
      night: 'Up late',
    },
    greetingLine: (greeting, header) => `${greeting} · ${header}`,
    time: (d) => `${pad(d.getHours())}:${pad(d.getMinutes())}`,
  },

  units: {
    times: (n) => plural(n, 'time', 'times'),
    count: (n) => `${n} ${plural(n, 'time', 'times')}`,
    hours: (n) => plural(n, 'hour', 'hours'),
    days: (n) => plural(n, 'day', 'days'),
    hoursValue: (n) => `${n} ${plural(n, 'hour', 'hours')}`,
    daysValue: (n) => `${n} ${plural(n, 'day', 'days')}`,
    justNow: 'just now',
  },

  bristol: {
    names: ['Hard pebbles', 'Lumpy log', 'Cracked log', 'Smooth log', 'Soft blobs', 'Mushy', 'Watery'],
    hints: [
      'Separate hard lumps, maybe a little constipated',
      'Log-shaped but lumpy, on the dry side',
      'A log with a few cracks, pretty good',
      'Smooth and soft. Perfect!',
      'Soft little blobs with clear edges',
      'Mushy and a bit loose',
      'Watery. Remember to drink plenty!',
    ],
    groups: { dry: 'Dry', ideal: 'Ideal', soft: 'Soft', loose: 'Loose' },
    label: (type, name) => `Type ${type} · ${name}`,
    spoken: (type, name) => `Type ${type} ${name}`,
    hint: (group, hint) => `${group} · ${hint}`,
    pickerLabel: 'Bristol stool scale',
    unsureLabel: 'Not sure about the shape',
    unsure: 'Not sure',
    skip: 'Skip',
  },

  mood: {
    noData: 'First time? Tap the big sticker below to log it',
    today: 'Your gut buddy sends you a little heart',
    yesterday: 'Remember to drink some water today',
    aWhile: 'Have some fruit and veg, and go for a little walk',
    tooLong: 'Drink water and eat more fiber. If you keep feeling unwell, see a doctor',
  },
  moodTitle: {
    noData: 'Nothing logged yet',
    today: 'All smooth today',
    yesterday: 'Went yesterday',
    days: (n) => `${n} days since the last one`,
  },

  app: {
    dbErrorTitle: 'Can’t open the local database',
    dbErrorBody:
      'Your browser may be in private mode or blocking site storage. PooPal needs IndexedDB to save your entries.',
    logged: (time) => `Logged · ${time}`,
    addDetails: 'Add details',
    undo: 'Undo',
    mainNav: 'Main navigation',
    tabToday: 'Today',
    tabStickers: 'Stickers',
    tabSettings: 'Settings',
  },

  home: {
    settings: 'Settings',
    todaySection: 'Today',
    todayCount: (n) => ['', ` ${plural(n, 'visit', 'visits')} today`],
    justVisited: 'Just went',
    sinceLast: (elapsed) => `${elapsed} since the last one`,
    addPast: 'Forgot one? Add it',
    recent: 'Recent visits',
    logLabel: (n) => `Log it, recorded right now. ${visits(n)} logged today`,
    logTitle: 'Log it',
    logFirst: 'Just went? Tap to log it',
    logNth: (n) => `Sticker no. ${n} today, tap to log it`,
    thisWeek: 'This week',
    dayLabel: (day, n) => `${day}, ${visits(n)}`,
    summary: 'How it’s going',
    last7Days: 'Last 7 days',
    howOften: 'About how often',
  },

  stats: {
    commonType: 'Usual shape',
    averageInterval: 'Average interval',
    perDayAll: 'Per day · all time',
    perDay30: 'Per day · last 30 days',
    last7: 'Last 7 days',
    last30: 'Last 30 days',
    total: 'Logged in total',
  },

  entry: {
    edit: 'Edit this entry',
    addDetailsHint: 'Tap to add the shape and a note',
    titleEdit: 'Edit',
    titleAdd: 'Add one',
    cancel: 'Cancel',
    save: 'Save',
    saveNew: 'Done',
    time: 'Time',
    date: 'Date',
    clock: 'Time of day',
    hourAgo: '1 hour ago',
    thisMorning: '8 am today',
    lastNight: '10 pm yesterday',
    shapeHeader: 'What did it look like? · Bristol scale',
    noteHeader: 'Anything to add?',
    notePlaceholder: 'e.g. Had hot pot last night, tummy hurt a bit',
    delete: 'Delete this entry',
    deleteMessage: 'Once it’s deleted, it’s gone for good',
    deleteConfirm: 'Delete',
  },

  history: {
    calendar: 'Calendar',
    list: 'List',
    trends: 'Trends',
    viewMode: 'View',
    add: 'Add one',
    title: 'My sticker book',
    emptyTitle: 'No stickers yet',
    emptyBody: 'Tap “Log it” on the home screen, or use the + at the top right to add an earlier one.',
    groupHeader: (day, n) => `${day} · ${visits(n)}`,
    more: 'Show earlier',
    footnote: 'Tap an entry to edit or delete it.',
    emptyDay: 'No stickers this day',
    monthTotal: (n) => `${n} ${plural(n, 'visit', 'visits')} in total`,
    prevMonth: 'Previous month',
    nextMonth: 'Next month',
    legendLess: 'Less',
    legendMore: 'More',
  },

  trends: {
    week: 'Weekly',
    month: 'Monthly',
    period: 'Period',
    howMany: 'How many times',
    sentence: (period, previous) =>
      period === 'week' ? ['This week ', `, last week ${previous}`] : ['This month ', `, last month ${previous}`],
    average: (period, average) =>
      period === 'week'
        ? `Average ${average} per week over the last 12 weeks (dashed line)`
        : `Average ${average} per month over the last 12 months (dashed line)`,
    shapes: 'Shapes, last 30 days',
    typed: (n) => `${n} with a shape`,
    shapesEmpty: 'Pick a shape when you log and the chart will appear here.',
    shapesFootnote: 'Types 3–4 are ideal; 1–2 lean dry, 6–7 lean loose.',
    allNumbers: 'All the numbers',
    chartLabel: (period, description) =>
      `Bar chart of visits over the last 12 ${period === 'week' ? 'weeks' : 'months'}: ${description}`,
    chartItem: (date, n) => `${date} ${visits(n)}`,
    listSeparator: ', ',
  },

  settings: {
    title: 'Settings',
    done: 'Done',
    looks: 'Looks',
    appearance: 'Appearance',
    appearanceOptions: { system: 'System', light: 'Light', dark: 'Dark' },
    language: 'Language',
    followSystem: 'System',
    remindersHeader: 'Reminders',
    inactivityFooter: (days, hour) =>
      `If it’s been more than ${days} ${plural(days, 'day', 'days')}, you’ll get a gentle nudge at ${hour} am.`,
    webLimit:
      'The web app can only send reminders while PooPal is open or was just backgrounded. If it’s fully closed, you’ll get them next time you open it.',
    inactivity: 'Nudge me after a while',
    inactivityDays: 'Days before a nudge',
    daily: 'Daily reminder to log',
    dailyTime: 'Reminder time',
    allowNotifications: 'Allow PooPal to send notifications',
    notificationsDenied: 'Notifications are turned off. Allow PooPal to notify you in your browser or system settings.',
    notificationsUnsupported: 'This browser doesn’t support web notifications.',
    notificationsIos:
      'On iPhone, first tap Share › Add to Home Screen in Safari, then open PooPal from the Home Screen to turn on reminders (iOS 16.4 or later).',
    decrease: 'Decrease',
    increase: 'Increase',
  },

  backup: {
    header: 'Backup',
    passwordTooShort: 'Use at least 4 characters',
    passwordMismatch: 'The passwords don’t match',
    exportFailed: (message) => `Export failed: ${message}`,
    importDone: (summary) => `Import complete: ${summary}`,
    importFailed: (message) => `Import failed: ${message}`,
    readFailed: (message) => `Couldn’t read the file: ${message}`,
    footerEncrypted: 'An encrypted backup can only be imported with its password. A forgotten password can’t be recovered.',
    footerPlain:
      'Exports a JSON file you can save to Files or send to yourself. Importing merges into your current entries and skips duplicates.',
    usePassword: 'Password-protect backups',
    newPassword: 'Password (at least 4 characters)',
    repeatPassword: 'Repeat password',
    preparing: 'Preparing…',
    export: 'Export backup',
    ready: 'Your backup is ready. Tap here to save it',
    import: 'Import backup',
    passwordTitle: 'This backup has a password',
    cancel: 'Cancel',
    importAction: 'Import',
    passwordPrompt: 'Enter the password you set when exporting.',
    passwordLabel: 'Backup password',
    ok: 'OK',
    fileWord: 'backup',
    encryptedWord: 'encrypted',
    summary: (inserts, fills, duplicates) => {
      const parts = [`${inserts} added`]
      if (fills > 0) parts.push(`${fills} filled in with a shape or note`)
      parts.push(`${duplicates} ${plural(duplicates, 'duplicate', 'duplicates')} skipped`)
      return parts.join(', ')
    },
    errors: {
      invalidFile: 'This isn’t a PooPal backup, or the file is damaged',
      passwordRequired: 'This backup has a password. Please enter it',
      wrongPassword: 'Wrong password, try again',
      unsupportedVersion: (version) => `Backup version ${version} is too new. Please update PooPal first`,
      cryptoUnavailable:
        'This browser can’t encrypt here (HTTPS is required). Please open PooPal from an HTTPS address',
    },
  },

  about: {
    privacy:
      'Your entries live only in this browser. No sign-up, and nobody else can see them. Export a backup before switching phones or browsers, or clearing site data.',
    install: 'In Safari on iPhone, tap Share › Add to Home Screen. It works just like an app, even offline.',
    demo: 'You’re looking at sample data. Changes won’t be saved to your entries.',
  },

  reminders: {
    inactivityTitle: (days) => `No poop logged for ${days} ${plural(days, 'day', 'days')}`,
    inactivityBody: 'Drink water and have some fruit and veg. Come log it in PooPal when you go!',
    dailyTitle: 'Have you gone today?',
    dailyBody: 'Tap into PooPal and add today’s page to your gut diary',
  },

  demoNotes: { 1: 'Hot pot last night', 6: 'Big cup of coffee this morning', 13: 'Tummy felt a bit off', 30: 'First day of the trip' },
}
