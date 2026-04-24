import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// 환경변수가 없거나 기본값이면 데모 모드
export const DEMO_MODE =
  !supabaseUrl ||
  !supabaseAnonKey ||
  supabaseUrl === "https://your-project-ref.supabase.co";

const createDemoQuery = (table, operation = "select") => {
  const isWrite = ["insert", "update"].includes(operation);
  const response = () => {
    if (isWrite) {
      return { data: null, error: { message: "데모 모드: Supabase 미연결" } };
    }

    if (["sns_credentials", "service_credentials", "members"].includes(table)) {
      return { data: [], error: null };
    }

    return { data: null, error: null };
  };

  const query = {
    select: () => query,
    order: () => query,
    eq: () => query,
    single: () => Promise.resolve(response()),
    then: (resolve, reject) => Promise.resolve(response()).then(resolve, reject),
  };

  return query;
};

// 데모 모드일 때 더미 클라이언트 (에러 방지용)
const dummyClient = {
  from: (table) => ({
    select: () => createDemoQuery(table),
    insert: () => createDemoQuery(table, "insert"),
    update: () => createDemoQuery(table, "update"),
    upsert: () => Promise.resolve({ error: null }),
    delete: () => createDemoQuery(table, "delete"),
  }),
  auth: {
    getSession: () => Promise.resolve({ data: { session: null }, error: null }),
    signInWithPassword: () => Promise.resolve({ data: null, error: { message: "데모 모드: Supabase 미연결" } }),
    signUp: () => Promise.resolve({ data: null, error: { message: "데모 모드: Supabase 미연결" } }),
    signOut: () => Promise.resolve({ error: null }),
  },
  functions: {
    invoke: () => Promise.resolve({ data: null, error: { message: "데모 모드: Supabase 미연결" } }),
  },
};

export const supabase = DEMO_MODE
  ? dummyClient
  : createClient(supabaseUrl, supabaseAnonKey);
