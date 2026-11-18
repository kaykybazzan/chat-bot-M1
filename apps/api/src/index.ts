import express from "express";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../generated/prisma/client";
import "dotenv/config";

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL })
const prisma = new PrismaClient({ adapter })
const app = express()

app.use(express.json())

app.get("/health", async (req, res) => {
    const usuarios = await prisma.users.count()
    res.json({ status: "ok", usuarios: usuarios })
})

app.listen(3000, () => {
    console.log("Server ligado na porta 3000")
})