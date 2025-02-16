import { prisma as prismaClient } from "@/db/prisma";

export const getPaginationParams = (request: Request, defaultPerPage = 20) => {
	const url = new URL(request.url);
	const page = Number(url.searchParams.get("page") || 1);
	const perPage = Number(url.searchParams.get("perPage") || defaultPerPage);

	return {
		page: Math.max(page, 1),
		perPage: [20, 50, 200].includes(perPage) ? perPage : defaultPerPage,
		skip: (page - 1) * perPage,
		take: perPage,
	};
};

export const getAdjacentDocumentIds = async (
	prisma: typeof prismaClient,
	currentId: string,
	orderBy = "id",
) => {
	const [prev, next] = await Promise.all([
		prisma.document.findFirst({
			where: { [orderBy]: { lt: currentId } },
			orderBy: { [orderBy]: "desc" },
			select: { id: true },
		}),
		prisma.document.findFirst({
			where: { [orderBy]: { gt: currentId } },
			orderBy: { [orderBy]: "asc" },
			select: { id: true },
		}),
	]);

	return {
		prevId: prev?.id,
		nextId: next?.id,
	};
};
