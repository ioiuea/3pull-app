import Link from "next/link";

const Home = () => (
  <div className="flex min-h-screen items-center justify-center bg-zinc-50 font-sans dark:bg-black">
    <main className="w-full max-w-3xl rounded-2xl border border-zinc-200 bg-white px-10 py-14 shadow-sm dark:border-zinc-800 dark:bg-zinc-950">
      <h1 className="text-3xl font-semibold tracking-tight text-zinc-900 dark:text-zinc-100">
        3pull Web Playground
      </h1>
      <p className="mt-4 text-base leading-7 text-zinc-600 dark:text-zinc-400">
        Zustand / Zod / SWR のサンプルページを用意しました。
      </p>
      <div className="mt-8 flex flex-wrap gap-3">
        <Link
          href="/sample"
          className="inline-flex items-center rounded-full bg-zinc-900 px-5 py-2 text-sm font-medium text-white transition hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900 dark:hover:bg-white"
        >
          サンプルページを見る
        </Link>
      </div>
    </main>
  </div>
);

export default Home;
