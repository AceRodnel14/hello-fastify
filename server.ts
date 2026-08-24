import Fastify from "fastify";
const app = Fastify({ logger: true });
const VAR: string = process.env.VAR ?? "world";
const PORT: number = Number(process.env.PORT ?? 8000);
const HOST: string = process.env.HOST ?? "0.0.0.0";
app.get("/", async () => {
  return { message: `Hello ${VAR}` };
});
app.get("/healthz", async () => {
  return { status: "ok" };
});
const address = await app.listen({ host: HOST, port: PORT });
app.log.info({ address }, "Server listening");
