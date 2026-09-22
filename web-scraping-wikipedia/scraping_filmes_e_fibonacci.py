# Importação das bibliotecas necessárias
import requests
from bs4 import BeautifulSoup
import pandas as pd

# URL da página da Wikipedia que contém a lista de filmes
url = "https://pt.wikipedia.org/wiki/Lista_do_BFI_com_os_50_filmes_que_voc%C3%AA_deveria_ver_at%C3%A9_os_14_anos"

# Cabeçalho para simular um navegador e evitar bloqueio da requisição
headers = {
    "User-Agent": "Mozilla/5.0"
}

# Envia uma requisição HTTP para acessar a página
response = requests.get(url, headers=headers)

# Verifica se a requisição foi bem sucedida
if response.status_code == 200:

    # Analisa o conteúdo HTML da página
    soup = BeautifulSoup(response.content, "html.parser")

    # Listas para armazenar os nomes dos filmes e os anos
    filmes = []
    anos = []

    # Percorre todos os elementos <li> da página
    for li in soup.find_all("li"):
        texto = li.get_text()

        # Verifica se o texto contém ano entre parênteses
        if "(" in texto and ")" in texto:

            # Separa o nome do filme e o ano
            partes = texto.rsplit("(", 1)
            filme = partes[0].strip()
            ano = partes[1].replace(")", "").strip()

            # Verifica se o ano é numérico
            if ano.isdigit():
                filmes.append(filme)
                anos.append(ano)

    # Cria um DataFrame com os dados coletados
    df = pd.DataFrame({
        "Nome": filmes,
        "Ano": anos
    })

    # Adiciona uma linha com o total de filmes
    df.loc[len(df)] = ["Total de Filmes", len(df)]

    # Salva os dados em um arquivo Excel
    df.to_excel("filmes.xlsx", index=False)

    print("Arquivo criado com sucesso")

else:
    print("Erro ao acessar a página")


# Função que gera a sequência de Fibonacci de forma recursiva
def fibonacci_recursivo(n):

    # Caso n seja menor ou igual a 0 retorna lista vazia
    if n <= 0:
        return []

    # Caso n seja 1 retorna apenas o primeiro número da sequência
    if n == 1:
        return [0]

    # Caso n seja 2 retorna os dois primeiros números
    if n == 2:
        return [0, 1]

    # Chamada recursiva para gerar a sequência até n-1
    seq = fibonacci_recursivo(n - 1)

    # Calcula o próximo número somando os dois últimos
    seq.append(seq[-1] + seq[-2])

    # Retorna a sequência completa
    return seq


# Define quantos números da sequência serão gerados
n = 10

# Executa a função
resultado = fibonacci_recursivo(n)

# Mostra o resultado
print(resultado)
