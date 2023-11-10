# SPDX-FileCopyrightText: 2023 Alexander Sosedkin <monk@unboiled.info>
# SPDX-License-Identifier: GPL-3.0

"""Test main module of pytest_icecream."""


def test_smoke() -> None:
    """Test that ic is available."""
    ic()  # type: ignore[name-defined]  # noqa: F821


def test_out() -> None:
    """Test that ic calls outputFunction and sees its position."""
    log: list[str] = []
    ic.configureOutput(  # type: ignore[name-defined]  # noqa: F821
        outputFunction=log.append,
    )
    ic('test')  # type: ignore[name-defined]  # noqa: F821
    ic()  # type: ignore[name-defined]  # noqa: F821
    ic.configureOutput(  # type: ignore[name-defined]  # noqa: F821
        outputFunction=None,
    )
    assert len(log) == 2  # noqa: PLR2004
    assert log[0] == "ic| 'test'"
    assert log[1].startswith('ic| test_smoke.py:19 in test_out() at ')
