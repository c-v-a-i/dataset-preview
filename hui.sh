#!/bin/bash
set -e

echo "Creating directories..."
mkdir -p app/components/ui
mkdir -p app/routes
mkdir -p prisma

echo "Creating .env..."
cat << 'EOF' > .env
DATABASE_URL="file:./dev.db"
EOF

echo "Creating biome.json..."
cat << 'EOF' > biome.json
{
	"\$schema": "https://biomejs.dev/schemas/1.5.3/schema.json",
	"files": {
		"ignore": ["build/**"]
	},
	"organizeImports": {
		"enabled": true
	},
	"linter": {
		"enabled": true,
		"rules": {
			"recommended": true
		}
	}
}
EOF

echo "Creating components.json..."
cat << 'EOF' > components.json
{
	"\$schema": "https://ui.shadcn.com/schema.json",
	"style": "new-york",
	"rsc": false,
	"tsx": true,
	"tailwind": {
		"config": "tailwind.config.js",
		"css": "app/globals.css",
		"baseColor": "slate",
		"cssVariables": true,
		"prefix": ""
	},
	"aliases": {
		"components": "@/components",
		"utils": "@/lib/styles"
	}
}
EOF

echo "Creating fly.toml..."
cat << 'EOF' > fly.toml
app = "remix-shadcn"
kill_signal = "SIGINT"
kill_timeout = 5
processes = []

[env]
PORT = "3000"

[mounts]
source = "remix_shadcn_data"
destination = "/data"

[[services]]
internal_port = 3000
processes = ["app"]
protocol = "tcp"
script_checks = []

[services.concurrency]
hard_limit = 50
soft_limit = 40
type = "connections"

[[services.ports]]
force_https = true
handlers = ["http"]
port = 80

[[services.ports]]
handlers = ["tls", "http"]
port = 443

[[services.tcp_checks]]
grace_period = "60s"
interval = "15s"
restart_limit = 6
timeout = "2s"

[[services.http_checks]]
grace_period = "5s"
headers = {}
interval = 10_000
method = "get"
path = "/healthcheck"
protocol = "http"
timeout = 2_000
tls_skip_verify = false
EOF

echo "Creating package.json..."
cat << 'EOF' > package.json
{
  "name": "dataset-preview",
  "private": true,
  "sideEffects": false,
  "type": "module",
  "scripts": {
    "build": "remix vite:build",
    "dev": "dotenv -- node ./server.js",
    "fix": "biome check . --apply",
    "lint": "biome check .",
    "start": "cross-env NODE_ENV=production node ./server.js",
    "typecheck": "tsc"
  },
  "dependencies": {
    "@chakra-ui/react": "^2.7.1",
    "@emotion/react": "^11.10.6",
    "@emotion/styled": "^11.10.6",
    "framer-motion": "^10.12.16",
    "@radix-ui/react-dropdown-menu": "2.0.6",
    "@radix-ui/react-icons": "1.3.0",
    "@radix-ui/react-slot": "1.0.2",
    "@remix-run/express": "^2.15.3",
    "@remix-run/node": "^2.15.3",
    "@remix-run/react": "^2.15.3",
    "@remix-run/serve": "^2.15.3",
    "class-variance-authority": "0.7.0",
    "clsx": "2.1.0",
    "compression": "1.7.4",
    "cross-env": "7.0.3",
    "express": "^4.21.2",
    "isbot": "5.1.0",
    "morgan": "1.10.0",
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "remix-utils": "7.5.0",
    "tailwind-merge": "2.2.1",
    "tailwindcss-animate": "1.0.7"
  },
  "devDependencies": {
    "@biomejs/biome": "1.5.3",
    "@remix-run/dev": "^2.15.3",
    "@tailwindcss/typography": "0.5.10",
    "@types/node": "20.11.19",
    "@types/react": "18.2.56",
    "@types/react-dom": "18.2.19",
    "autoprefixer": "10.4.17",
    "dotenv-cli": "7.3.0",
    "postcss": "8.4.35",
    "tailwindcss": "3.4.1",
    "typescript": "5.3.3",
    "vite": "5.1.3",
    "vite-env-only": "2.2.0",
    "vite-tsconfig-paths": "4.3.1"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

echo "Creating app/components files..."

# theme-switcher.tsx
cat << 'EOF' > app/components/theme-switcher.tsx
export type Theme = "light" | "dark" | "system";

/**
 * This component is used to set the theme based on the value at hydration time.
 * If no value is found, it will default to the user's system preference and
 * coordinates with the ThemeSwitcherScript to prevent a flash of unstyled content
 * and a React hydration mismatch.
 */
export function ThemeSwitcherSafeHTML({
	children,
	lang,
	...props
}: React.HTMLProps<HTMLHtmlElement> & { lang: string }) {
	const dataTheme =
		typeof document === "undefined"
			? undefined
			: document.documentElement.getAttribute("data-theme") || undefined;

	return (
		<html {...props} lang={lang} data-theme={dataTheme}>
			{children}
		</html>
	);
}

/**
 * This script will run on the client to set the theme based on the value in
 * localStorage. If no value is found, it will default to the user's system
 * preference.
 *
 * IMPORTANT: This script should be placed at the end of the <head> tag to
 * prevent a flash of unstyled content.
 */
export function ThemeSwitcherScript() {
	return (
		<script
			// biome-ignore lint/security/noDangerouslySetInnerHtml: <explanation>
			dangerouslySetInnerHTML={{
				__html: \`
          (function() {
            var theme = localStorage.getItem("theme");
            if (theme) {
              document.documentElement.setAttribute("data-theme", theme);
            }
          })();
        \`,
			}}
		/>
	);
}

export function getTheme() {
	return validateTheme(
		typeof document === "undefined" ? "system" : localStorage.getItem("theme"),
	);
}

/**
 * This function will toggle the theme between light and dark and store the
 * value in localStorage.
 */
export function toggleTheme() {
	let currentTheme = validateTheme(localStorage.getItem("theme"));
	if (currentTheme === "system") {
		currentTheme = window.matchMedia("(prefers-color-scheme: dark)").matches
			? "dark"
			: "light";
	}
	const newTheme = currentTheme === "light" ? "dark" : "light";
	localStorage.setItem("theme", newTheme);
	document.documentElement.setAttribute("data-theme", newTheme);
}

export function setTheme(theme: Theme | string) {
	let themeToSet: Theme | null = validateTheme(theme);
	if (themeToSet === "system") {
		themeToSet = null;
	}
	if (themeToSet) {
		localStorage.setItem("theme", themeToSet);
		document.documentElement.setAttribute("data-theme", themeToSet);
	} else {
		localStorage.removeItem("theme");
		document.documentElement.removeAttribute("data-theme");
	}
}

function validateTheme(theme: string | null): Theme {
	return theme === "light" || theme === "dark" || theme === "system"
		? theme
		: "system";
}
EOF

# global-pending-indicator.tsx
cat << 'EOF' > app/components/global-pending-indicator.tsx
import { useNavigation } from "@remix-run/react";

import { cn } from "@/lib/styles";

export function GlobalPendingIndicator() {
	const navigation = useNavigation();
	const pending = navigation.state !== "idle";

	return (
		<div className={cn("fixed top-0 left-0 right-0", { hidden: !pending })}>
			<div className="h-0.5 w-full bg-muted overflow-hidden">
				<div className="animate-progress w-full h-full bg-muted-foreground origin-left-right" />
			</div>
		</div>
	);
}
EOF

# header.tsx
cat << 'EOF' > app/components/header.tsx
import { LaptopIcon, MoonIcon, SunIcon } from "@radix-ui/react-icons";
import { Link } from "@remix-run/react";
import * as React from "react";
import { useHydrated } from "remix-utils/use-hydrated";

import {
	getTheme,
	setTheme as setSystemTheme,
} from "@/components/theme-switcher";
import { Button } from "@/components/ui/button";
import {
	DropdownMenu,
	DropdownMenuContent,
	DropdownMenuItem,
	DropdownMenuLabel,
	DropdownMenuSeparator,
	DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export function Header() {
	const hydrated = useHydrated();
	const [, rerender] = React.useState({});
	const setTheme = React.useCallback((theme: string) => {
		setSystemTheme(theme);
		rerender({});
	}, []);
	const theme = getTheme();

	return (
		<header className="flex items-center justify-between px-4 py-2 md:py-4">
			<div className="flex items-center space-x-4">
				<Link className="flex items-center space-x-2" to="/">
					{/* <HomeIcon className="h-6 w-6" /> */}
					<span className="text-lg font-bold">shadcn</span>
				</Link>
			</div>
			<DropdownMenu>
				<DropdownMenuTrigger asChild>
					<Button
						className="w-10 h-10 rounded-full border"
						size="icon"
						variant="ghost"
					>
						<span className="sr-only">Theme selector</span>
						{!hydrated ? null : theme === "dark" ? (
							<MoonIcon />
						) : theme === "light" ? (
							<SunIcon />
						) : (
							<LaptopIcon />
						)}
					</Button>
				</DropdownMenuTrigger>
				<DropdownMenuContent className="mt-2">
					<DropdownMenuLabel>Theme</DropdownMenuLabel>
					<DropdownMenuSeparator />
					<DropdownMenuItem asChild>
						<button
							type="button"
							className="w-full"
							onClick={() => setTheme("light")}
							aria-selected={theme === "light"}
						>
							Light
						</button>
					</DropdownMenuItem>
					<DropdownMenuItem asChild>
						<button
							type="button"
							className="w-full"
							onClick={() => setTheme("dark")}
							aria-selected={theme === "dark"}
						>
							Dark
						</button>
					</DropdownMenuItem>
					<DropdownMenuItem asChild>
						<button
							type="button"
							className="w-full"
							onClick={() => setTheme("system")}
							aria-selected={theme === "system"}
						>
							System
						</button>
					</DropdownMenuItem>
				</DropdownMenuContent>
			</DropdownMenu>
		</header>
	);
}
EOF

echo "Creating app/components/ui files..."

# button.tsx
cat << 'EOF' > app/components/ui/button.tsx
import { Slot } from "@radix-ui/react-slot";
import { type VariantProps, cva } from "class-variance-authority";
import * as React from "react";

import { cn } from "@/lib/styles";

const buttonVariants = cva(
	"inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50",
	{
		variants: {
			variant: {
				default:
					"bg-primary text-primary-foreground shadow hover:bg-primary/90",
				destructive:
					"bg-destructive text-destructive-foreground shadow-sm hover:bg-destructive/90",
				outline:
					"border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground",
				secondary:
					"bg-secondary text-secondary-foreground shadow-sm hover:bg-secondary/80",
				ghost: "hover:bg-accent hover:text-accent-foreground",
				link: "text-primary underline-offset-4 hover:underline",
			},
			size: {
				default: "h-9 px-4 py-2",
				sm: "h-8 rounded-md px-3 text-xs",
				lg: "h-10 rounded-md px-8",
				icon: "h-9 w-9",
			},
		},
		defaultVariants: {
			variant: "default",
			size: "default",
		},
	},
);

export interface ButtonProps
	extends React.ButtonHTMLAttributes<HTMLButtonElement>,
		VariantProps<typeof buttonVariants> {
	asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
	({ className, variant, size, asChild = false, ...props }, ref) => {
		const Comp = asChild ? Slot : "button";
		return (
			<Comp
				className={cn(buttonVariants({ variant, size, className }))}
				ref={ref}
				{...props}
			/>
		);
	},
);
Button.displayName = "Button";

export { Button, buttonVariants };
EOF

# dropdown-menu.tsx
cat << 'EOF' > app/components/ui/dropdown-menu.tsx
import * as DropdownMenuPrimitive from "@radix-ui/react-dropdown-menu";
import {
	CheckIcon,
	ChevronRightIcon,
	DotFilledIcon,
} from "@radix-ui/react-icons";
import * as React from "react";

import { cn } from "@/lib/styles";

const DropdownMenu = DropdownMenuPrimitive.Root;

const DropdownMenuTrigger = DropdownMenuPrimitive.Trigger;

const DropdownMenuGroup = DropdownMenuPrimitive.Group;

const DropdownMenuPortal = DropdownMenuPrimitive.Portal;

const DropdownMenuSub = DropdownMenuPrimitive.Sub;

const DropdownMenuRadioGroup = DropdownMenuPrimitive.RadioGroup;

const DropdownMenuSubTrigger = React.forwardRef<
	React.ElementRef<typeof DropdownMenuPrimitive.SubTrigger>,
	React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.SubTrigger> & {
		inset?: boolean;
	}
>(({ className, inset, children, ...props }, ref) => (
	<DropdownMenuPrimitive.SubTrigger
		ref={ref}
		className={cn(
			"flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none focus:bg-accent data-[state=open]:bg-accent",
			inset && "pl-8",
			className,
		)}
		{...props}
	>
		{children}
		<ChevronRightIcon className="ml-auto h-4 w-4" />
	</DropdownMenuPrimitive.SubTrigger>
));
DropdownMenuSubTrigger.displayName =
	DropdownMenuPrimitive.SubTrigger.displayName;

const DropdownMenuSubContent = React.forwardRef<
	React.ElementRef<typeof DropdownMenuPrimitive.SubContent>,
	React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.SubContent>
>(({ className, ...props }, ref) => (
	<DropdownMenuPrimitive.SubContent
		ref={ref}
		className={cn(
			"z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-lg data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
			className,
		)}
		{...props}
	/>
));
DropdownMenuSubContent.displayName =
	DropdownMenuPrimitive.SubContent.displayName;

const DropdownMenuContent = React.forwardRef<
	React.ElementRef<typeof DropdownMenuPrimitive.Content>,
	React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Content>
>(({ className, sideOffset = 4, ...props }, ref) => (
	<DropdownMenuPrimitive.Portal>
		<DropdownMenuPrimitive.Content
			ref={ref}
			sideOffset={sideOffset}
			className={cn(
				"z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md",
				"data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
				className,
			)}
			{...props}
		/>
	</DropdownMenuPrimitive.Portal>
));
DropdownMenuContent.displayName = DropdownMenuPrimitive.Content.displayName;

const DropdownMenuItem = React.forwardRef<
	React.ElementRef<typeof DropdownMenuPrimitive.Item>,
	React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Item> & {
		inset?: boolean;
	}
>(({ className, inset, ...props }, ref) => (
	<DropdownMenuPrimitive.Item
		ref={ref}
		className={cn(
			"relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none transition-colors focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
			inset && "pl-8",
			className,
		)}
		{...props}
	/>
));
DropdownMenuItem.displayName = DropdownMenuPrimitive.Item.displayName;

const DropdownMenuCheckboxItem = React.forwardRef<
	React.ElementRef<typeof DropdownMenuPrimitive.CheckboxItem>,
	React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.CheckboxItem>
>(({ className, children, checked, ...props }, ref) => (
	<DropdownMenuPrimitive.CheckboxItem
		ref={ref}
		className={cn(
			"relative flex cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none transition-colors focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
			className,
		)}
		checked={checked}
		{...props}
	>
		<span className="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
			<DropdownMenuPrimitive.ItemIndicator>
				<CheckIcon className="h-4 w-4" />
			</DropdownMenuPrimitive.ItemIndicator>
		</span>
		{children}
	</DropdownMenuPrimitive.CheckboxItem>
));
DropdownMenuCheckboxItem.displayName =
	DropdownMenuPrimitive.CheckboxItem.displayName;

const DropdownMenuRadioItem = React.forwardRef<
	React.ElementRef<typeof DropdownMenuPrimitive.RadioItem>,
	React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.RadioItem>
>(({ className, children, ...props }, ref) => (
	<DropdownMenuPrimitive.RadioItem
		ref={ref}
		className={cn(
			"relative flex cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none transition-colors focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
			className,
		)}
		{...props}
	>
		<span className="absolute left-2 flex h-3.5 w-3.5 items-center justify-center">
			<DropdownMenuPrimitive.ItemIndicator>
				<DotFilledIcon className="h-4 w-4 fill-current" />
			</DropdownMenuPrimitive.ItemIndicator>
		</span>
		{children}
	</DropdownMenuPrimitive.RadioItem>
));
DropdownMenuRadioItem.displayName = DropdownMenuPrimitive.RadioItem.displayName;

const DropdownMenuLabel = React.forwardRef<
	React.ElementRef<typeof DropdownMenuPrimitive.Label>,
	React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Label> & {
		inset?: boolean;
	}
>(({ className, inset, ...props }, ref) => (
	<DropdownMenuPrimitive.Label
		ref={ref}
		className={cn(
			"px-2 py-1.5 text-sm font-semibold",
			inset && "pl-8",
			className,
		)}
		{...props}
	/>
));
DropdownMenuLabel.displayName = DropdownMenuPrimitive.Label.displayName;

const DropdownMenuSeparator = React.forwardRef<
	React.ElementRef<typeof DropdownMenuPrimitive.Separator>,
	React.ComponentPropsWithoutRef<typeof DropdownMenuPrimitive.Separator>
>(({ className, ...props }, ref) => (
	<DropdownMenuPrimitive.Separator
		ref={ref}
		className={cn("-mx-1 my-1 h-px bg-muted", className)}
		{...props}
	/>
));
DropdownMenuSeparator.displayName = DropdownMenuPrimitive.Separator.displayName;

const DropdownMenuShortcut = ({
	className,
	...props
}: React.HTMLAttributes<HTMLSpanElement>) => {
	return (
		<span
			className={cn("ml-auto text-xs tracking-widest opacity-60", className)}
			{...props}
		/>
	);
};
DropdownMenuShortcut.displayName = "DropdownMenuShortcut";

export {
	DropdownMenu,
	DropdownMenuTrigger,
	DropdownMenuContent,
	DropdownMenuItem,
	DropdownMenuCheckboxItem,
	DropdownMenuRadioItem,
	DropdownMenuLabel,
	DropdownMenuSeparator,
	DropdownMenuShortcut,
	DropdownMenuGroup,
	DropdownMenuPortal,
	DropdownMenuSub,
	DropdownMenuSubContent,
	DropdownMenuSubTrigger,
	DropdownMenuRadioGroup,
};
EOF

echo "Creating app/routes files..."

# healthcheck.ts
cat << 'EOF' > app/routes/healthcheck.ts
export function loader() {
	return new Response("OK", {
		status: 200,
		headers: {
			"Content-Type": "text/plain",
		},
	});
}
EOF

# index.tsx (Messages UI using Chakra UI)
cat << 'EOF' > app/routes/index.tsx
import { json, LoaderFunction } from "@remix-run/node";
import { useLoaderData } from "@remix-run/react";
import { Flex, Box, Image, Text } from "@chakra-ui/react";
import { db } from "~/db.server";

type Message = {
  id: number;
  content: string;
  imageUrl: string | null;
};

export const loader: LoaderFunction = async () => {
  const messages = await db.message.findMany({
    orderBy: { createdAt: "desc" },
  });
  return json({ messages });
};

export default function Index() {
  const { messages } = useLoaderData<{ messages: Message[] }>();
  return (
    <Flex direction="column" p={4}>
      <Text fontSize="2xl" mb={4}>Messages</Text>
      {messages.map((message) => (
        <Flex key={message.id} p={4} mb={2} borderWidth="1px" borderRadius="md" align="center">
          {message.imageUrl ? (
            <Image src={message.imageUrl} alt="Avatar" boxSize="50px" mr={4} borderRadius="full" />
          ) : (
            <Box boxSize="50px" mr={4} bg="gray.300" borderRadius="full" />
          )}
          <Text>{message.content}</Text>
        </Flex>
      ))}
    </Flex>
  );
}
EOF

echo "Creating entry files..."

# entry.client.tsx
cat << 'EOF' > app/entry.client.tsx
import { RemixBrowser } from "@remix-run/react";
import { StrictMode, startTransition } from "react";
import { hydrateRoot } from "react-dom/client";

startTransition(() => {
	hydrateRoot(
		document,
		<StrictMode>
			<RemixBrowser />
		</StrictMode>,
	);
});
EOF

# entry.server.tsx
cat << 'EOF' > app/entry.server.tsx
import { PassThrough } from "node:stream";

import type { AppLoadContext, EntryContext } from "@remix-run/node";
import { createReadableStreamFromReadable } from "@remix-run/node";
import { RemixServer } from "@remix-run/react";
import { isbot } from "isbot";
import { renderToPipeableStream } from "react-dom/server";

const ABORT_DELAY = 5_000;

export default function handleRequest(
	request: Request,
	responseStatusCode: number,
	responseHeaders: Headers,
	remixContext: EntryContext,
	loadContext: AppLoadContext,
) {
	const isBot = isbot(request.headers.get("user-agent"));

	let status = responseStatusCode;
	const headers = new Headers(responseHeaders);
	headers.set("Content-Type", "text/html; charset=utf-8");

	return new Promise((resolve, reject) => {
		let shellRendered = false;
		const { pipe, abort } = renderToPipeableStream(
			<RemixServer
				context={remixContext}
				url={request.url}
				abortDelay={ABORT_DELAY}
			/>,
			{
				onAllReady() {
					if (!isBot) return;

					resolve(
						new Response(
							createReadableStreamFromReadable(pipe(new PassThrough())),
							{
								headers,
								status,
							},
						),
					);
				},
				onShellReady() {
					shellRendered = true;

					if (isBot) return;

					resolve(
						new Response(
							createReadableStreamFromReadable(pipe(new PassThrough())),
							{
								headers,
								status,
							},
						),
					);
				},
				onShellError(error: unknown) {
					reject(error);
				},
				onError(error: unknown) {
					status = 500;
					if (shellRendered) {
						console.error(error);
					}
				},
			},
		);

		setTimeout(abort, ABORT_DELAY);
	});
}
EOF

echo "Creating app/root.tsx..."

cat << 'EOF' > app/root.tsx
import {
	Links,
	Meta,
	Outlet,
	Scripts,
	ScrollRestoration,
	isRouteErrorResponse,
	useRouteError,
} from "@remix-run/react";
import { ChakraProvider } from "@chakra-ui/react";

import { GlobalPendingIndicator } from "@/components/global-pending-indicator";
import { Header } from "@/components/header";
import {
	ThemeSwitcherSafeHTML,
	ThemeSwitcherScript,
} from "@/components/theme-switcher";

import "./globals.css";

function App({ children }: { children: React.ReactNode }) {
	return (
		<ThemeSwitcherSafeHTML lang="en">
			<head>
				<meta charSet="utf-8" />
				<meta name="viewport" content="width=device-width, initial-scale=1" />
				<Meta />
				<Links />
				<ThemeSwitcherScript />
			</head>
			<body>
				<ChakraProvider>
					<GlobalPendingIndicator />
					<Header />
					{children}
					<ScrollRestoration />
					<Scripts />
				</ChakraProvider>
			</body>
		</ThemeSwitcherSafeHTML>
	);
}

export default function Root() {
	return (
		<App>
			<Outlet />
		</App>
	);
}

export function ErrorBoundary() {
	const error = useRouteError();
	let status = 500;
	let message = "An unexpected error occurred.";
	if (isRouteErrorResponse(error)) {
		status = error.status;
		switch (error.status) {
			case 404:
				message = "Page Not Found";
				break;
		}
	} else {
		console.error(error);
	}

	return (
		<App>
			<div className="container prose py-8">
				<h1>{status}</h1>
				<p>{message}</p>
			</div>
		</App>
	);
}
EOF

echo "Creating Prisma files..."

# db.server.ts
cat << 'EOF' > app/db.server.ts
import { PrismaClient } from "@prisma/client";

let db: PrismaClient;

if (process.env.NODE_ENV === "production") {
  db = new PrismaClient();
} else {
  if (!(global as any).prisma) {
    (global as any).prisma = new PrismaClient();
  }
  db = (global as any).prisma;
}

export { db };
EOF

# schema.prisma
cat << 'EOF' > prisma/schema.prisma
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model Message {
  id        Int      @id @default(autoincrement())
  content   String
  imageUrl  String?
  createdAt DateTime @default(now())
}
EOF

echo "Project setup complete."
