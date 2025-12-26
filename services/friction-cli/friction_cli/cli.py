"""Main CLI interface for Friction Logger."""

import sys
from typing import List, Optional

import click
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich import box

from friction_cli import __version__
from friction_cli.config import ConfigManager
from friction_cli.client import InsightsClient, InsightCreate

console = Console()


def get_client(ctx: click.Context) -> InsightsClient:
    """Get configured Insights API client."""
    if ctx.obj is None:
        ctx.obj = {}
    if "config_manager" not in ctx.obj:
        ctx.obj["config_manager"] = ConfigManager()
    config_manager = ctx.obj["config_manager"]
    config = config_manager.config
    return InsightsClient(config.api_url, config.api_key)


@click.group()
@click.version_option(version=__version__)
@click.option(
    "--config",
    type=click.Path(),
    help="Path to configuration file (default: ~/.friction/config.yaml)",
)
@click.pass_context
def main(ctx, config):
    """Fawkes Friction Logger - Log developer friction points in real-time.

    Log friction points you encounter during development and track them
    in the Fawkes Insights database for analysis and improvement.
    """
    ctx.ensure_object(dict)
    ctx.obj["config_manager"] = ConfigManager(config)


@main.command()
@click.option("--title", "-t", help="Brief title of the friction point")
@click.option("--description", "-d", help="Detailed description of the friction")
@click.option("--category", "-c", help="Category (e.g., 'CI/CD', 'Documentation', 'Tooling')")
@click.option(
    "--priority",
    "-p",
    type=click.Choice(["low", "medium", "high", "critical"], case_sensitive=False),
    help="Priority level",
)
@click.option("--tags", "-T", multiple=True, help="Tags (can specify multiple times)")
@click.option("--interactive", "-i", is_flag=True, help="Use interactive mode")
@click.pass_context
def log(ctx, title, description, category, priority, tags, interactive):
    """Log a new friction point.

    Examples:

      # Quick log
      friction log -t "Slow CI builds" -d "Maven builds taking 20+ minutes"

      # Interactive mode
      friction log -i

      # With category and tags
      friction log -t "Missing docs" -c Documentation -T docs -T improvement
    """
    client = get_client(ctx)
    config_manager = ctx.obj["config_manager"]
    config = config_manager.config

    # Check API connectivity
    if not client.health_check():
        console.print("[red]✗[/red] Cannot connect to Insights API at", config.api_url)
        console.print("  Check your configuration with: friction config show")
        sys.exit(1)

    # Interactive mode
    if interactive or not (title and description):
        console.print(
            Panel.fit(
                "[bold cyan]Friction Logger - Interactive Mode[/bold cyan]\n" "Let's capture that friction point!",
                box=box.DOUBLE,
            )
        )

        if not title:
            title = Prompt.ask("[yellow]What's the friction about?[/yellow] (brief title)")

        if not description:
            description = Prompt.ask("[yellow]Describe the friction[/yellow] (what happened, when, impact)")

        if not category:
            # Show available categories
            try:
                categories = client.list_categories()
                console.print("\n[cyan]Available categories:[/cyan]")
                for i, cat in enumerate(categories, 1):
                    console.print(f"  {i}. {cat['name']}")
                console.print()
                category = Prompt.ask("[yellow]Category[/yellow]", default=config.default_category)
            except Exception:
                category = Prompt.ask("[yellow]Category[/yellow]", default=config.default_category)

        if not priority:
            priority = Prompt.ask(
                "[yellow]Priority[/yellow]",
                choices=["low", "medium", "high", "critical"],
                default=config.default_priority,
            )

        if not tags:
            tags_input = Prompt.ask("[yellow]Tags[/yellow] (comma-separated, optional)", default="")
            tags = [t.strip() for t in tags_input.split(",") if t.strip()]

    # Create the insight
    try:
        insight = InsightCreate(
            title=title,
            description=description,
            content=f"# {title}\n\n{description}\n\n**Logged via CLI**",
            category_name=category,
            tags=list(tags) + ["friction"],  # Always add 'friction' tag
            priority=priority or config.default_priority,
            source="CLI",
            author=config.author,
            metadata={
                "type": "friction",
                "cli_version": __version__,
            },
        )

        result = client.create_insight(insight)

        console.print()
        console.print(
            Panel.fit(
                f"[bold green]✓ Friction point logged successfully![/bold green]\n\n"
                f"ID: {result.get('id')}\n"
                f"Title: {title}\n"
                f"Category: {category}\n"
                f"Priority: {priority or config.default_priority}",
                box=box.DOUBLE,
                border_style="green",
            )
        )

    except Exception as e:
        console.print(f"[red]✗ Failed to log friction:[/red] {e}")
        sys.exit(1)


@main.command()
@click.option("--category", "-c", help="Filter by category")
@click.option("--priority", "-p", help="Filter by priority")
@click.option("--limit", "-l", type=int, default=10, help="Number of results to show")
@click.pass_context
def list(ctx, category, priority, limit):
    """List recent friction points.

    Examples:

      # List last 10 friction points
      friction list

      # Filter by category
      friction list -c "CI/CD"

      # Filter by priority
      friction list -p high -l 20
    """
    client = get_client(ctx)

    try:
        insights = client.list_insights(
            category=category,
            priority=priority,
            limit=limit,
        )

        if not insights:
            console.print("[yellow]No friction points found.[/yellow]")
            return

        table = Table(title=f"Recent Friction Points ({len(insights)} results)", box=box.ROUNDED)
        table.add_column("ID", style="cyan", width=6)
        table.add_column("Title", style="white", width=40)
        table.add_column("Category", style="magenta", width=15)
        table.add_column("Priority", style="yellow", width=10)
        table.add_column("Status", style="green", width=10)

        for insight in insights:
            priority_style = {
                "critical": "[red]",
                "high": "[yellow]",
                "medium": "[white]",
                "low": "[dim]",
            }.get(insight.get("priority", "medium").lower(), "[white]")

            table.add_row(
                str(insight.get("id")),
                insight.get("title", "")[:40],
                insight.get("category", {}).get("name", "N/A")
                if isinstance(insight.get("category"), dict)
                else str(insight.get("category", "N/A")),
                f"{priority_style}{insight.get('priority', 'medium')}[/]",
                insight.get("status", "new"),
            )

        console.print(table)

    except Exception as e:
        console.print(f"[red]✗ Failed to list friction points:[/red] {e}")
        sys.exit(1)


@main.command()
@click.argument("friction_id", type=int)
@click.pass_context
def show(ctx, friction_id):
    """Show details of a specific friction point.

    Examples:

      friction show 123
    """
    client = get_client(ctx)

    try:
        insight = client.get_insight(friction_id)

        console.print()
        console.print(
            Panel.fit(
                f"[bold cyan]{insight.get('title')}[/bold cyan]\n\n"
                f"[dim]ID:[/dim] {insight.get('id')}\n"
                f"[dim]Category:[/dim] {insight.get('category', {}).get('name', 'N/A')}\n"
                f"[dim]Priority:[/dim] {insight.get('priority', 'medium')}\n"
                f"[dim]Status:[/dim] {insight.get('status', 'new')}\n"
                f"[dim]Author:[/dim] {insight.get('author', 'Unknown')}\n"
                f"[dim]Created:[/dim] {insight.get('created_at', 'N/A')}\n\n"
                f"[bold]Description:[/bold]\n{insight.get('description', 'N/A')}\n\n"
                f"[dim]Tags:[/dim] {', '.join(t.get('name', '') if isinstance(t, dict) else str(t) for t in insight.get('tags', []))}",
                box=box.DOUBLE,
            )
        )

    except Exception as e:
        console.print(f"[red]✗ Failed to show friction point:[/red] {e}")
        sys.exit(1)


@main.group()
def categories():
    """Manage friction categories."""
    pass


@categories.command(name="list")
@click.pass_context
def categories_list(ctx):
    """List all available categories."""
    client = get_client(ctx)

    try:
        cats = client.list_categories()

        if not cats:
            console.print("[yellow]No categories found.[/yellow]")
            return

        table = Table(title="Available Categories", box=box.ROUNDED)
        table.add_column("ID", style="cyan", width=6)
        table.add_column("Name", style="white", width=30)
        table.add_column("Description", style="dim", width=50)

        for cat in cats:
            table.add_row(
                str(cat.get("id")),
                cat.get("name", ""),
                cat.get("description", "")[:50] if cat.get("description") else "",
            )

        console.print(table)

    except Exception as e:
        console.print(f"[red]✗ Failed to list categories:[/red] {e}")
        sys.exit(1)


@main.group()
def config_group():
    """Manage CLI configuration."""
    pass


@config_group.command(name="show")
@click.pass_context
def config_show(ctx):
    """Show current configuration."""
    config_manager = ctx.obj["config_manager"]
    config = config_manager.config

    console.print()
    console.print(
        Panel.fit(
            f"[bold cyan]Friction CLI Configuration[/bold cyan]\n\n"
            f"[dim]Config file:[/dim] {config_manager.config_path}\n"
            f"[dim]API URL:[/dim] {config.api_url}\n"
            f"[dim]API Key:[/dim] {'*' * 10 if config.api_key else 'Not set'}\n"
            f"[dim]Default Category:[/dim] {config.default_category}\n"
            f"[dim]Default Priority:[/dim] {config.default_priority}\n"
            f"[dim]Author:[/dim] {config.author or 'Not set (using git config)'}",
            box=box.DOUBLE,
        )
    )


@config_group.command(name="init")
@click.option("--api-url", help="Insights API URL")
@click.option("--api-key", help="API key (optional)")
@click.option("--author", help="Your name")
@click.pass_context
def config_init(ctx, api_url, api_key, author):
    """Initialize configuration interactively."""
    config_manager = ctx.obj["config_manager"]

    console.print(
        Panel.fit(
            "[bold cyan]Friction CLI Configuration Setup[/bold cyan]\n" "Let's configure the CLI for your environment",
            box=box.DOUBLE,
        )
    )

    if not api_url:
        api_url = Prompt.ask(
            "[yellow]Insights API URL[/yellow]", default="http://insights-service.fawkes.svc.cluster.local:8000"
        )

    if not author:
        author = Prompt.ask("[yellow]Your name[/yellow]", default="")

    if not api_key:
        if Confirm.ask("[yellow]Do you have an API key?[/yellow]", default=False):
            api_key = Prompt.ask("[yellow]API key[/yellow]", password=True)

    from friction_cli.config import FrictionConfig

    config = FrictionConfig(
        api_url=api_url,
        api_key=api_key if api_key else None,
        author=author if author else None,
    )

    config_manager.save(config)

    console.print()
    console.print(f"[green]✓[/green] Configuration saved to {config_manager.config_path}")

    # Test connection
    client = InsightsClient(config.api_url, config.api_key)
    if client.health_check():
        console.print("[green]✓[/green] Successfully connected to Insights API")
    else:
        console.print("[yellow]⚠[/yellow] Could not connect to Insights API - check the URL")


# Add config group with proper name
main.add_command(config_group, name="config")


if __name__ == "__main__":
    main()
