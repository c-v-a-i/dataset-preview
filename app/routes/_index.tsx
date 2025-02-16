import { json } from "@remix-run/node"
import { useLoaderData } from "@remix-run/react"
import { DocumentList } from "@/components/document-list"
import { getPaginationParams } from "@/lib/pagination"
import { prisma } from "@/db/prisma"

export const loader = async ({ request }: { request: Request }) => {
  const { page, perPage, skip, take } = getPaginationParams(request)
  
  const [documents, totalCount] = await Promise.all([
    prisma.document.findMany({
      skip,
      take,
      orderBy: { id: 'asc' },
      select: { id: true }
    }),
    prisma.document.count()
  ])

  return json({ documents, page, perPage, totalCount })
}

export default function Index() {
  const { documents, page, perPage, totalCount } = useLoaderData<typeof loader>()
  
  return (
    <div className="container py-8">
      <h1 className="text-2xl font-bold mb-6">Documents</h1>
      <DocumentList 
        documents={documents}
        page={page}
        perPage={perPage}
        totalCount={totalCount}
      />
    </div>
  )
}
