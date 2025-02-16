import { Button } from "@/components/ui/button";
import {
	ChevronLeftIcon,
	ChevronRightIcon,
	MixerHorizontalIcon,
} from "@radix-ui/react-icons";
import { Link } from "@remix-run/react";

export function DocumentList({
	documents,
	page,
	perPage,
	totalCount,
}: {
	documents: Array<{ id: string }>;
	page: number;
	perPage: number;
	totalCount: number;
}) {
	const totalPages = Math.ceil(totalCount / perPage);

	return (
		<div className="space-y-4">
			<div className="flex items-center justify-between">
				<div className="flex gap-2">
					<Button variant="outline" size="sm" asChild>
						<Link to={"?perPage=20"}>
							<MixerHorizontalIcon className="mr-2" /> 20
						</Link>
					</Button>
					<Button variant="outline" size="sm" asChild>
						<Link to={"?perPage=50"}>50</Link>
					</Button>
					<Button variant="outline" size="sm" asChild>
						<Link to={"?perPage=200"}>200</Link>
					</Button>
				</div>

				<div className="flex gap-2">
					<Button variant="outline" size="sm" asChild disabled={page === 1}>
						<Link to={`?page=${page - 1}&perPage=${perPage}`}>
							<ChevronLeftIcon className="h-4 w-4" />
						</Link>
					</Button>
					<span className="px-4 py-2 text-sm">
						Page {page} of {totalPages}
					</span>
					<Button
						variant="outline"
						size="sm"
						asChild
						disabled={page >= totalPages}
					>
						<Link to={`?page=${page + 1}&perPage=${perPage}`}>
							<ChevronRightIcon className="h-4 w-4" />
						</Link>
					</Button>
				</div>
			</div>

			<div className="rounded-md border">
				<table className="w-full">
					<tbody>
						{documents.map((doc) => (
							<tr key={doc.id} className="border-b hover:bg-muted/50">
								<td className="p-4">
									<Link to={`/document/${doc.id}`} className="block">
										Document {doc.id}
									</Link>
								</td>
							</tr>
						))}
					</tbody>
				</table>
			</div>
		</div>
	);
}
