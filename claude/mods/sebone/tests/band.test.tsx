import { expect, test } from 'claude-code/testing'

const QUOTES = [
  { text: '骨は守る', source: 'A' },
  { text: '自分が自分をどう思うか' },
]

const BAND = {
  plugin: 'sebone',
  component: 'AbovePrompt',
  props: {
    hasSurvey: false,
    isWorking: false,
    maxRows: 10,
    bodyColumns: 80,
    scroll: { offset: 0, bodyRows: 9 },
    view: {},
  },
} as const

const SURFACES = ['terminal', 'desktop'] as const

const QUOTE_TEXT = /^🗿 (骨は守る|自分が自分をどう思うか)$/

test('セッション開始時に名言ファイルの1件が本文だけで表示される', async ($, on) => {
  on('fs.read', () => ({ value: JSON.stringify(QUOTES) }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...BAND, surface })
    const row = await ui.find({ type: 'Text', text: QUOTE_TEXT })
    expect(row?.text).toMatch(QUOTE_TEXT)
    await ui.unmount()
  }
})

test('プロンプト送信のたびに直前とは別の名言に変わる', async ($, on) => {
  on('fs.read', () => ({ value: JSON.stringify(QUOTES) }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('prompt.submit', (_, e) => e)

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  const shown = async () => {
    const ui = await $.ui.mount({ ...BAND, surface: 'desktop' })
    const text = (await ui.find({ type: 'Text', text: QUOTE_TEXT }))?.text
    await ui.unmount()
    return text
  }

  let prev = await shown()
  for (let i = 0; i < 5; i++) {
    await $.prompt.submit({ text: 'hi' })
    const now = await shown()
    expect(now).not.toBe(prev)
    prev = now
  }
})

test('名言ファイルが読めなくても送信は通り、バンドはエンジンに任せる', async ($, on) => {
  on('fs.read', () => {
    throw new Error('missing')
  })
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('prompt.submit', (_, e) => e)
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  const result = await $.prompt.submit({ text: 'hi' })
  expect(result.text).toBe('hi')

  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ ...BAND, surface })
    expect((await ui.find({ type: 'Text', text: /engine/ }))?.text).toBe('engine')
    await ui.unmount()
  }
})
