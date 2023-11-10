# SPDX-FileCopyrightText: 2023 Alexander Sosedkin <monk@unboiled.info>
# SPDX-License-Identifier: GPL-3.0

"""Main module of pytest_icecream."""

import builtins
import typing

import icecream  # type: ignore[import-untyped]
import pytest


@pytest.fixture(autouse=True)
def _autoinstall_ic() -> typing.Iterator[None]:
    builtins.ic = icecream.ic  # type: ignore[attr-defined]
    yield
    del builtins.ic  # type: ignore[attr-defined]


__all__: list[str] = []
