"""Main CLI interface for Feedback Tool."""

import sys
from typing import Optional

import click
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm, IntPrompt
from rich import box

from feedback_cli import __version__
from feedback_cli.config import ConfigManager, FeedbackConfig
from feedback_cli.client import FeedbackClient, FeedbackSubmission
from feedback_cli.queue import OfflineQueue

console = Console()


def get_client(ctx: click.Context) -> FeedbackClient:
    """Get configured Feedback API client."""
    if ctx.obj is None:
        ctx.obj = {}
    if "config_manager" not in ctx.obj:
        ctx.obj["config_manager"] = ConfigManager()
    config_manager = ctx.obj["config_manager"]
    config = config_manager.config
    return FeedbackClient(config.api_url, config.api_key)


def get_queue(ctx: click.Context) -> OfflineQueue:
    """Get offline queue manager."""
    config_manager = ctx.obj["config_manager"]
    config = config_manager.config
    return OfflineQueue(config.queue_path)


@click.group()
@click.version_option(version=__version__)
@click.option(
    "--config",
    type=click.Path(),
    help="Path to configuration file (default: ~/.fawkes-feedback/config.yaml)",
)
@click.pass_context
def main(ctx, config):
    """Fawkes Feedback CLI - Submit feedback from the terminal.

    Submit feedback about the Fawkes platform without leaving your terminal.
    Supports interactive mode and offline queueing when the service is unavailable.
    """
    ctx.ensure_object(dict)
    ctx.obj["config_manager"] = ConfigManager(config)


@main.command()
@click.option("--rating", "-r", type=int, help="Rating from 1-5")
@click.option("--category", "-c", help="Feedback category (e.g., 'UI/UX', 'Performance', 'Documentation')")
@click.option("--comment", "-m", help="Feedback comment")
@click.option("--email", "-e", help="Your email for follow-up (optional)")
@click.option("--page-url", "-u", help="Page URL where feedback is about")
@click.option(
    "--type",
    "-t",
    "feedback_type",
    type=click.Choice(["feedback", "bug_report", "feature_request"], case_sensitive=False),
    help="Type of feedback",
)
@click.option("--interactive", "-i", is_flag=True, help="Use interactive mode")
@click.pass_context
def submit(ctx, rating, category, comment, email, page_url, feedback_type, interactive):
    """Submit new feedback.

    Examples:

      # Quick submit
      fawkes-feedback submit -r 5 -c "UI/UX" -m "Love the new dashboard!"

      # Interactive mode
      fawkes-feedback submit -i

      # Bug report
      fawkes-feedback submit -t bug_report -r 2 -c "Jenkins" -m "Build failing on main branch"
    """
    client = get_client(ctx)
    config_manager = ctx.obj["config_manager"]
    config = config_manager.config
    queue = get_queue(ctx)

    # Check API connectivity first
    api_available = client.health_check()

    if not api_available and not config.offline_mode:
        console.print("[red]✗[/red] Cannot connect to Feedback API at", config.api_url)
        console.print("  Offline mode is disabled. Enable it with: fawkes-feedback config set-offline true")
        sys.exit(1)
    elif not api_available:
        console.print("[yellow]⚠[/yellow] Feedback API unavailable. Will queue for later submission.")

    # Interactive mode
    if interactive or not (rating and category and comment):
        console.print(
            Panel.fit(
                "[bold cyan]Fawkes Feedback - Interactive Mode[/bold cyan]\n"
                "Share your feedback about the Fawkes platform!",
                box=box.DOUBLE,
            )
        )

        if not rating:
            rating = IntPrompt.ask(
                "[yellow]Rate your experience (1-5)[/yellow]", default=3, choices=["1", "2", "3", "4", "5"]
            )

        if not category:
            console.print("\n[cyan]Common categories:[/cyan]")
            categories = ["UI/UX", "Performance", "Documentation", "Features", "Bug Report", "Other"]
            for i, cat in enumerate(categories, 1):
                console.print(f"  {i}. {cat}")
            console.print()
            category = Prompt.ask("[yellow]Category[/yellow]", default=config.default_category)

        if not comment:
            comment = Prompt.ask("[yellow]Your feedback[/yellow] (what went well or what could be improved)")

        if not email:
            if Confirm.ask("[yellow]Would you like to provide an email for follow-up?[/yellow]", default=False):
                email = Prompt.ask("[yellow]Email address[/yellow]")

        if not page_url:
            if Confirm.ask("[yellow]Is this about a specific page/URL?[/yellow]", default=False):
                page_url = Prompt.ask("[yellow]Page URL[/yellow]")

        if not feedback_type:
            feedback_type = Prompt.ask(
                "[yellow]Feedback type[/yellow]",
                choices=["feedback", "bug_report", "feature_request"],
                default="feedback",
            )

    # Validate required fields
    if not rating or not category or not comment:
        console.print("[red]✗[/red] Missing required fields: rating, category, and comment are required")
        sys.exit(1)

    # Create feedback submission
    try:
        feedback = FeedbackSubmission(
            rating=rating,
            category=category,
            comment=comment,
            email=email,
            page_url=page_url,
            feedback_type=feedback_type or "feedback",
        )

        if api_available:
            # Submit directly
            result = client.submit_feedback(feedback)

            console.print()
            console.print(
                Panel.fit(
                    f"[bold green]✓ Feedback submitted successfully![/bold green]\n\n"
                    f"ID: {result.get('id')}\n"
                    f"Rating: {'⭐' * rating}\n"
                    f"Category: {category}\n"
                    f"Type: {feedback_type or 'feedback'}\n"
                    f"Status: {result.get('status', 'open')}",
                    box=box.DOUBLE,
                    border_style="green",
                )
            )
        else:
            # Queue for later
            queue.add(feedback.model_dump())
            console.print()
            console.print(
                Panel.fit(
                    f"[bold yellow]⏳ Feedback queued for later submission[/bold yellow]\n\n"
                    f"Rating: {'⭐' * rating}\n"
                    f"Category: {category}\n"
                    f"Queue size: {queue.size()} items\n\n"
                    f"[dim]Run 'fawkes-feedback sync' to retry submission when online[/dim]",
                    box=box.DOUBLE,
                    border_style="yellow",
                )
            )

    except Exception as e:
        console.print(f"[red]✗ Failed to submit feedback:[/red] {e}")
        sys.exit(1)


@main.command()
@click.option("--category", "-c", help="Filter by category")
@click.option("--status", "-s", help="Filter by status")
@click.option("--limit", "-l", type=int, default=10, help="Number of results to show")
@click.pass_context
def list(ctx, category, status, limit):
    """List recent feedback submissions.

    Examples:

      # List last 10 feedback items
      fawkes-feedback list

      # Filter by category
      fawkes-feedback list -c "UI/UX"

      # Filter by status
      fawkes-feedback list -s resolved -l 20
    """
    client = get_client(ctx)

    if not client.health_check():
        console.print("[red]✗[/red] Cannot connect to Feedback API")
        console.print("  Check your configuration with: fawkes-feedback config show")
        sys.exit(1)

    try:
        response = client.list_feedback(
            category=category,
            status=status,
            limit=limit,
        )

        items = response.get("items", [])

        if not items:
            console.print("[yellow]No feedback found.[/yellow]")
            return

        table = Table(title=f"Recent Feedback ({len(items)} of {response.get('total', 0)} total)", box=box.ROUNDED)
        table.add_column("ID", style="cyan", width=6)
        table.add_column("Rating", style="yellow", width=8)
        table.add_column("Category", style="magenta", width=15)
        table.add_column("Type", style="blue", width=15)
        table.add_column("Status", style="green", width=12)
        table.add_column("Date", style="dim", width=12)

        for item in items:
            rating_stars = "⭐" * item.get("rating", 0)
            created_at = item.get("created_at", "")[:10]  # Just the date part

            table.add_row(
                str(item.get("id")),
                rating_stars,
                item.get("category", "")[:15],
                item.get("feedback_type", "feedback")[:15],
                item.get("status", "open"),
                created_at,
            )

        console.print(table)

    except Exception as e:
        console.print(f"[red]✗ Failed to list feedback:[/red] {e}")
        sys.exit(1)


@main.command()
@click.argument("feedback_id", type=int)
@click.pass_context
def show(ctx, feedback_id):
    """Show details of a specific feedback item.

    Examples:

      fawkes-feedback show 123
    """
    client = get_client(ctx)

    if not client.health_check():
        console.print("[red]✗[/red] Cannot connect to Feedback API")
        sys.exit(1)

    try:
        item = client.get_feedback(feedback_id)

        rating_stars = "⭐" * item.get("rating", 0)
        sentiment = item.get("sentiment", "N/A")
        sentiment_style = {
            "positive": "[green]",
            "neutral": "[white]",
            "negative": "[red]",
        }.get(sentiment, "[white]")

        console.print()
        console.print(
            Panel.fit(
                f"[bold cyan]Feedback #{item.get('id')}[/bold cyan]\n\n"
                f"[dim]Rating:[/dim] {rating_stars}\n"
                f"[dim]Category:[/dim] {item.get('category', 'N/A')}\n"
                f"[dim]Type:[/dim] {item.get('feedback_type', 'feedback')}\n"
                f"[dim]Status:[/dim] {item.get('status', 'open')}\n"
                f"[dim]Sentiment:[/dim] {sentiment_style}{sentiment}[/]\n"
                f"[dim]Created:[/dim] {item.get('created_at', 'N/A')}\n"
                f"[dim]Updated:[/dim] {item.get('updated_at', 'N/A')}\n\n"
                f"[bold]Comment:[/bold]\n{item.get('comment', 'N/A')}\n\n"
                f"[dim]Email:[/dim] {item.get('email') or 'Not provided'}\n"
                f"[dim]Page URL:[/dim] {item.get('page_url') or 'Not provided'}\n"
                f"[dim]GitHub Issue:[/dim] {item.get('github_issue_url') or 'None'}",
                box=box.DOUBLE,
            )
        )

    except Exception as e:
        console.print(f"[red]✗ Failed to show feedback:[/red] {e}")
        sys.exit(1)


@main.command()
@click.pass_context
def sync(ctx):
    """Sync queued feedback to the service.

    Attempts to submit all queued feedback items when the API is available.
    """
    client = get_client(ctx)
    queue = get_queue(ctx)

    if not client.health_check():
        console.print("[red]✗[/red] Cannot connect to Feedback API")
        console.print("  Queue will remain intact for later sync")
        sys.exit(1)

    queued_items = queue.get_all()

    if not queued_items:
        console.print("[green]✓[/green] Queue is empty, nothing to sync")
        return

    console.print(f"[cyan]Syncing {len(queued_items)} queued feedback items...[/cyan]\n")

    success_count = 0
    failed_indices = []

    for i, item in enumerate(queued_items):
        try:
            feedback = FeedbackSubmission(**item)
            result = client.submit_feedback(feedback)
            console.print(
                f"[green]✓[/green] Submitted feedback #{result.get('id')} (queued: {item.get('queued_at', 'N/A')[:10]})"
            )
            success_count += 1
            # Mark for removal by setting to None
            queued_items[i] = None
        except Exception as e:
            console.print(f"[red]✗[/red] Failed to submit item {i+1}: {e}")
            queue.increment_attempts(i)
            failed_indices.append(i)

    # Remove successfully submitted items
    for i in reversed(range(len(queued_items))):
        if queued_items[i] is None:
            queue.remove(i)

    console.print()
    console.print(
        Panel.fit(
            f"[bold cyan]Sync Complete[/bold cyan]\n\n"
            f"✓ Successfully submitted: {success_count}\n"
            f"✗ Failed: {len(failed_indices)}\n"
            f"Remaining in queue: {queue.size()}",
            box=box.DOUBLE,
        )
    )


@main.command(name="queue")
@click.pass_context
def queue_status(ctx):
    """Show offline queue status.

    Display all feedback items waiting to be submitted.
    """
    queue = get_queue(ctx)
    queued_items = queue.get_all()

    if not queued_items:
        console.print("[green]✓[/green] Queue is empty")
        return

    table = Table(title=f"Offline Queue ({len(queued_items)} items)", box=box.ROUNDED)
    table.add_column("#", style="cyan", width=4)
    table.add_column("Rating", style="yellow", width=8)
    table.add_column("Category", style="magenta", width=15)
    table.add_column("Queued At", style="dim", width=12)
    table.add_column("Attempts", style="red", width=8)

    for i, item in enumerate(queued_items, 1):
        rating_stars = "⭐" * item.get("rating", 0)
        queued_at = item.get("queued_at", "")[:10]

        table.add_row(
            str(i),
            rating_stars,
            item.get("category", "")[:15],
            queued_at,
            str(item.get("attempts", 0)),
        )

    console.print(table)
    console.print(f"\n[dim]Run 'fawkes-feedback sync' to submit queued items[/dim]")


@main.group()
def config():
    """Manage CLI configuration."""
    pass


@config.command(name="show")
@click.pass_context
def config_show(ctx):
    """Show current configuration."""
    config_manager = ctx.obj["config_manager"]
    config_obj = config_manager.config

    console.print()
    console.print(
        Panel.fit(
            f"[bold cyan]Fawkes Feedback CLI Configuration[/bold cyan]\n\n"
            f"[dim]Config file:[/dim] {config_manager.config_path}\n"
            f"[dim]API URL:[/dim] {config_obj.api_url}\n"
            f"[dim]API Key:[/dim] {'*' * 10 if config_obj.api_key else 'Not set'}\n"
            f"[dim]Default Category:[/dim] {config_obj.default_category}\n"
            f"[dim]Author:[/dim] {config_obj.author or 'Not set (using git config)'}\n"
            f"[dim]Offline Mode:[/dim] {config_obj.offline_mode}\n"
            f"[dim]Queue Path:[/dim] {config_obj.queue_path}",
            box=box.DOUBLE,
        )
    )


@config.command(name="init")
@click.option("--api-url", help="Feedback API URL")
@click.option("--api-key", help="API key (optional)")
@click.option("--author", help="Your name")
@click.pass_context
def config_init(ctx, api_url, api_key, author):
    """Initialize configuration interactively."""
    config_manager = ctx.obj["config_manager"]

    console.print(
        Panel.fit(
            "[bold cyan]Fawkes Feedback CLI Configuration Setup[/bold cyan]\n"
            "Let's configure the CLI for your environment",
            box=box.DOUBLE,
        )
    )

    if not api_url:
        api_url = Prompt.ask(
            "[yellow]Feedback API URL[/yellow]", default="http://feedback-service.fawkes.svc.cluster.local:8000"
        )

    if not author:
        author = Prompt.ask("[yellow]Your name[/yellow]", default="")

    if not api_key:
        if Confirm.ask("[yellow]Do you have an API key?[/yellow]", default=False):
            api_key = Prompt.ask("[yellow]API key[/yellow]", password=True)

    config_obj = FeedbackConfig(
        api_url=api_url,
        api_key=api_key if api_key else None,
        author=author if author else None,
    )

    config_manager.save(config_obj)

    console.print()
    console.print(f"[green]✓[/green] Configuration saved to {config_manager.config_path}")

    # Test connection
    client = FeedbackClient(config_obj.api_url, config_obj.api_key)
    if client.health_check():
        console.print("[green]✓[/green] Successfully connected to Feedback API")
    else:
        console.print("[yellow]⚠[/yellow] Could not connect to Feedback API - check the URL")


@config.command(name="set-offline")
@click.argument("enabled", type=bool)
@click.pass_context
def config_set_offline(ctx, enabled):
    """Enable or disable offline mode.

    Examples:

      fawkes-feedback config set-offline true
      fawkes-feedback config set-offline false
    """
    config_manager = ctx.obj["config_manager"]
    config_obj = config_manager.config
    config_obj.offline_mode = enabled
    config_manager.save(config_obj)

    status = "enabled" if enabled else "disabled"
    console.print(f"[green]✓[/green] Offline mode {status}")


if __name__ == "__main__":
    main()
