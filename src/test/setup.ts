// Same fixed zone as the iOS tests, so calendar-day boundaries are deterministic.
process.env.TZ = 'Asia/Shanghai'

import { beforeEach } from 'vitest'
import { setLanguagePreference } from '../i18n'

// The source strings are Chinese; tests for other languages switch explicitly.
beforeEach(() => setLanguagePreference('zh'))
