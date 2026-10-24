import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Quote } from '../types'

// $.fs.read は ~ を展開しないので絶対パスで持つ
const QUOTES_PATH = '/Users/tokizo/ghq/github.com/tokizuoh/dotfiles/claude/quotes.json'

const current = atom({ plugin: 'sebone', key: 'current' } as const, null)

const isQuote = (v: unknown): v is Quote =>
  typeof v === 'object' && v !== null && typeof (v as Quote).text === 'string'

const loadQuotes = async ($: EngineInterface): Promise<Quote[]> => {
  try {
    const parsed: unknown = JSON.parse((await $.fs.read(QUOTES_PATH)) as string)
    return Array.isArray(parsed) ? parsed.filter(isQuote) : []
  } catch {
    return []
  }
}

// 名言を足したらすぐ反映されるよう、毎回ファイルを読み直す
const pick = async ($: EngineInterface) => {
  const quotes = await loadQuotes($)
  const prev = await read($, current)
  const candidates =
    quotes.length > 1 ? quotes.filter(q => q.text !== prev?.text) : quotes
  const next = candidates[Math.floor(Math.random() * candidates.length)] ?? null
  await update($, current, () => next)
}

export const register: Register = on => {
  // 名言の選び直しに失敗しても、セッション開始やプロンプト送信は止めない
  on('session.start', async ($, e, next) => {
    await pick($).catch(() => {})
    return next(e)
  })

  // 時間切れでも送信を止めないよう、登録側の catch でも素通しにする
  on('prompt.submit', async ($, e, next) => {
    await pick($).catch(() => {})
    return next(e)
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const quote = await read($, current)
    if (e.props.hasSurvey || quote === null) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box>
        <Text dimColor>🗿 {quote.text}</Text>
      </Box>
    )
  })
}
