export default class VoteService {
  static async submit({ id, value }) {
    const csrf = document
      .querySelector("meta[name='csrf-token']")
      ?.getAttribute("content");

    try {
      const response = await fetch("/translation_reviews/vote", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrf
        },
        body: JSON.stringify({ id, vote: value })
      });

      if (response.redirected || response.status === 401) {
        window.location = "/users/sign_in";
        return null;
      }

      return await response.json();
    } catch (e) {
      console.error("VoteService failed:", e);
      return null;
    }
  }
}
