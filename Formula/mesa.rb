class Mesa < Formula
  include Language::Python::Virtualenv

  desc "Graphics Library"
  homepage "https://www.mesa3d.org/"
  url "https://archive.mesa3d.org/mesa-21.0.0.tar.xz"
  sha256 "e6204e98e6a8d77cf9dc5d34f99dd8e3ef7144f3601c808ca0dd26ba522e0d84"
  license "MIT"
  head "https://gitlab.freedesktop.org/mesa/mesa.git"

  livecheck do
    url "https://archive.mesa3d.org/"
    regex(/href=.*?mesa[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 arm64_big_sur: "a2b617ac47e7b62689b159f6cec26c0ab58232f1107e97d5aa7d526716985ac8"
    sha256 big_sur:       "1156d7e7613c4c85d641e88dfa0dd8e5ccd26dff5921ef0043319d2f9566121a"
    sha256 catalina:      "aed8cf54ca7e305a825cbcc0f5f784c1269e76516ef5622c31da77869547f0e9"
    sha256 mojave:        "977792ae909b0fb0e1f98ca7404ae2b9bd1d9a7acaadc415ce2481e869083860"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.9" => :build
  depends_on "expat"
  depends_on "gettext"
  depends_on "libx11"
  depends_on "libxcb"
  depends_on "libxdamage"
  depends_on "libxext"

  resource "Mako" do
    url "https://files.pythonhosted.org/packages/5c/db/2d2d88b924aa4674a080aae83b59ea19d593250bfe5ed789947c21736785/Mako-1.1.4.tar.gz"
    sha256 "17831f0b7087c313c0ffae2bcbbd3c1d5ba9eeac9c38f2eb7b50e8c99fe9d5ab"
  end

  resource "glxgears.c" do
    url "https://gitlab.freedesktop.org/mesa/demos/-/raw/faaa319d704ac677c3a93caadedeb91a4a74b7a7/src/xdemos/glxgears.c"
    sha256 "3873db84d708b5d8b3cac39270926ba46d812c2f6362da8e6cd0a1bff6628ae6"
  end

  resource "gl_wrap.h" do
    url "https://gitlab.freedesktop.org/mesa/demos/-/raw/faaa319d704ac677c3a93caadedeb91a4a74b7a7/src/util/gl_wrap.h"
    sha256 "c727b2341d81c2a1b8a0b31e46d24f9702a1ec55c8be3f455ddc8d72120ada72"
  end

  patch do
    url "https://gitlab.freedesktop.org/mesa/mesa/-/commit/50064ad367449afad03c927f7e572c138b05c5d4.patch"
    sha256 "aa3fa361a8626d442aefdac922a7193612b77cab2410452acee40b6dbc10a800"
  end

  def install
    ENV.prepend_path "PATH", Formula["python@3.9"].opt_libexec/"bin"

    venv_root = libexec/"venv"
    venv = virtualenv_create(venv_root, "python3")
    venv.pip_install resource("Mako")

    ENV.prepend_path "PATH", "#{venv_root}/bin"

    mkdir "build" do
      system "meson", *std_meson_args, "..", "-Db_ndebug=true"
      system "ninja"
      system "ninja", "install"
    end
  end

  test do
    %w[glxgears.c gl_wrap.h].each { |r| resource(r).stage(testpath) }
    flags = %W[
      -I#{include}
      -L#{lib}
      -L#{Formula["libx11"].lib}
      -L#{Formula["libxext"].lib}
      -lGL
      -lX11
      -lXext
      -lm
    ]
    system ENV.cc, "glxgears.c", "-o", "gears", *flags
  end
end
