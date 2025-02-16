import { DocumentViewer } from "@/components/document-viewer";
import { prisma } from "@/db/prisma";
import { getAdjacentDocumentIds } from "@/lib/pagination";
import { json } from "@remix-run/node";
import { useLoaderData } from "@remix-run/react";

export const loader = async ({
	params,
}: { params: { documentId: string } }) => {
	const documentId = params.documentId;

	const [document, adjacentIds] = await Promise.all([
		prisma.document.findUnique({
			where: { id: documentId },
			include: {
				messages: true,
				DocumentTranscription: true,
			},
		}),
		getAdjacentDocumentIds(prisma, documentId),
	]);

	if (!document) {
		throw new Response("Document not found", { status: 404 });
	}

	const documentBlob = Buffer.from(document.documentBlob).toString("base64");

	const transcription =
		document.DocumentTranscription.sort((a, b) => b.version - a.version)[0]
			?.document_representation || "";

	return json({
		document: {
			...document,
			documentBlob, // Now this is a base64 string
		},
		messages: document.messages,
		transcription,
		prevId: adjacentIds.prevId,
		nextId: adjacentIds.nextId,
	});
};

export default function DocumentPage() {
	const { document, messages, transcription, prevId, nextId } =
		useLoaderData<typeof loader>();

	return (
		<div className="container py-8">
			<DocumentViewer
				document={document}
				messages={messages}
				transcription={transcription}
				prevId={prevId}
				nextId={nextId}
			/>
		</div>
	);
}
