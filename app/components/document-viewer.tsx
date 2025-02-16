import { Button } from "@/components/ui/button";
import {
	Dialog,
	DialogContent,
	DialogHeader,
	DialogTitle,
	DialogTrigger,
} from "@/components/ui/dialog";
import {
	Document as PrismaDocument,
	DocumentMessage,
	DocumentTranscription,
} from "@prisma/client";
import { ChevronLeftIcon, ChevronRightIcon } from "@radix-ui/react-icons";
import { Link } from "@remix-run/react";

type DocumentViewerProps = {
	document: Omit<PrismaDocument, "documentBlob"> & { documentBlob: string };
	messages: DocumentMessage[];
	transcription: DocumentTranscription["document_representation"];
	prevId?: string;
	nextId?: string;
};

export const DocumentViewer = ({
	document: { documentBlob, id: documentId },
	messages,
	transcription,
	prevId,
	nextId,
}: DocumentViewerProps) => {
	const imageSrc = `data:image/png;base64,${documentBlob}`;

	return (
		<div className="grid grid-cols-1 lg:grid-cols-2 gap-8 h-[calc(100vh-160px)]">
			{/* Image Section */}
			<div className="bg-muted rounded-lg p-4 overflow-hidden">
				<img
					src={imageSrc}
					alt="PrismaDocument preview"
					className="object-contain w-full h-full"
				/>
			</div>

			{/* Messages Section */}
			<div className="flex flex-col gap-4">
				<div className="flex justify-between items-center mb-4">
					<div className="flex gap-2">
						{prevId && (
							<Button variant="outline" size="sm" asChild>
								<Link to={`/document/${prevId}`}>
									<ChevronLeftIcon className="h-4 w-4 mr-2" />
									Previous
								</Link>
							</Button>
						)}
						{nextId && (
							<Button variant="outline" size="sm" asChild>
								<Link to={`/document/${nextId}`}>
									Next
									<ChevronRightIcon className="h-4 w-4 ml-2" />
								</Link>
							</Button>
						)}
					</div>

					<div className="flex gap-2">
						<div className="p-4 rounded-lg bg-background border">
							<p className="text-sm font-medium text-muted-foreground">
								{documentId}
							</p>
						</div>
					</div>

					<Dialog>
						<DialogTrigger asChild>
							<Button variant="outline">View Transcription</Button>
						</DialogTrigger>
						<DialogContent className="max-w-2xl max-h-[80vh] overflow-auto">
							<DialogHeader>
								<DialogTitle>Document Transcription</DialogTitle>
							</DialogHeader>
							<pre className="whitespace-pre-wrap">{transcription}</pre>
						</DialogContent>
					</Dialog>
				</div>

				<div className="space-y-4 overflow-auto pr-4">
					{messages.slice(1).map((message, i) => (
						// biome-ignore lint/suspicious/noArrayIndexKey: <explanation>
						<div key={i} className="p-4 rounded-lg bg-background border">
							<div className="text-sm font-medium text-muted-foreground">
								{message.role}
							</div>
							{message.content.split("\\n").map((content, i) => (
								<p>{content}</p>
							))}
						</div>
					))}
				</div>
			</div>
		</div>
	);
};
