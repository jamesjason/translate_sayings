export default class LanguagePreference {
  static COOKIE_NAME = "ts_target_language"

  static read() {
    const match = document.cookie.match(
      new RegExp(`${this.COOKIE_NAME}=([^;]+)`)
    )
    return match ? match[1] : null
  }

  static write(code) {
    document.cookie =
      `${this.COOKIE_NAME}=${code}; path=/; max-age=${60 * 60 * 24 * 365}`
  }
}
